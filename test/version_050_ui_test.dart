import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_todo/app.dart';
import 'package:daily_todo/domain/entities/task.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/domain/usecases/manage_reminder.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'package:daily_todo/presentation/controllers/reminder_controller.dart';
import 'package:daily_todo/presentation/widgets/task_editor.dart';
import 'package:daily_todo/presentation/widgets/reference_widgets.dart';
import 'support/fakes.dart';

void main() {
  late MemoryTaskRepository repository;
  late PlannerController planner;
  late ReminderController reminder;
  setUp(() async {
    repository = MemoryTaskRepository();
    planner = PlannerController(
      ManageTasks(repository),
      clock: () => DateTime(2027, 1, 2),
    );
    reminder = ReminderController(
      ManageReminder(MemoryReminderRepository(), FakeScheduler()),
    );
    await planner.initialize();
    await reminder.initialize();
  });
  tearDown(() {
    planner.dispose();
    reminder.dispose();
  });

  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(DailyApp(planner: planner, reminder: reminder));
    await tester.pumpAndSettle();
  }

  Finder card(String id) => find.byKey(ValueKey('task-card-$id'));
  Finder tab(int index) => find.byKey(ValueKey('nav-section-$index'));

  testWidgets(
    'Whole card toggles, check is on the right, completion moves smoothly and reverses',
    (tester) async {
      for (final (id, title) in [
        ('a', 'Первая'),
        ('b', 'Вторая'),
        ('c', 'Третья'),
      ]) {
        await planner.save(Task(id: id, title: title, day: '2027-01-02'));
      }
      await open(tester);
      final firstY = tester.getTopLeft(card('a')).dy;
      final lastY = tester.getTopLeft(card('c')).dy;
      expect(
        tester.getCenter(find.byKey(const ValueKey('check-a'))).dx,
        greaterThan(tester.getCenter(card('a')).dx),
      );
      await tester.tap(find.text('Первая'));
      await tester.pump();
      await tester.pump(); // Start the post-layout position animation's ticker.
      await tester.pump(const Duration(milliseconds: 140));
      expect(planner.tasks.first.done, true);
      final duringY = tester.getTopLeft(card('a')).dy;
      expect(duringY, greaterThan(firstY));
      expect(duringY, lessThan(lastY));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(card('a')).dy,
        greaterThan(tester.getTopLeft(card('c')).dy),
      );
      expect(find.byType(TaskEditor), findsNothing);
      await tester.tap(card('a'));
      await tester.pumpAndSettle();
      expect(planner.tasks.first.done, false);
      expect(
        tester.getTopLeft(card('a')).dy,
        lessThan(tester.getTopLeft(card('b')).dy),
      );
      repository.fail = true;
      await tester.tap(card('a'));
      await tester.pumpAndSettle();
      expect(planner.tasks.first.done, false);
      expect(
        tester.getTopLeft(card('a')).dy,
        lessThan(tester.getTopLeft(card('b')).dy),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Long press exposes two actions without changing completion', (
    tester,
  ) async {
    await planner.save(const Task(id: 'a', title: 'Задача', day: '2027-01-02'));
    await open(tester);
    await tester.longPress(card('a'));
    await tester.pumpAndSettle();
    expect(planner.tasks.single.done, false);
    expect(find.byKey(const ValueKey('task-edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-delete')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('task-delete')));
    await tester.pumpAndSettle();
    expect(planner.tasks, isEmpty);
    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(planner.tasks.single.id, 'a');
    expect(planner.tasks.single.done, false);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Tabs swipe both ways, taps animate and all navigation sections have equal size',
    (tester) async {
      await open(tester, scale: 2);
      final dimensions = [for (var i = 0; i < 4; i++) tester.getSize(tab(i))];
      expect(dimensions.every((size) => size == dimensions.first), true);
      final pageFinder = find.byKey(const ValueKey('tab-pages'));
      PageController pages() => tester.widget<PageView>(pageFinder).controller!;
      for (var target = 1; target <= 3; target++) {
        await tester.drag(pageFinder, const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(pages().page, target.toDouble());
      }
      await tester.drag(pageFinder, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(pages().page, 2);
      await tester.tap(tab(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(pages().page, greaterThan(0));
      expect(pages().page, lessThan(2));
      await tester.pumpAndSettle();
      expect(pages().page, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Slow shorter swipes advance; tiny drags cancel and indicator follows the finger',
    (tester) async {
      await open(tester);
      final pageFinder = find.byKey(const ValueKey('tab-pages'));
      final indicator = find.byKey(const ValueKey('nav-indicator'));
      PageController pages() => tester.widget<PageView>(pageFinder).controller!;
      Future<void> dragSlowly(double distance) async {
        final gesture = await tester.startGesture(tester.getCenter(pageFinder));
        await gesture.moveBy(
          Offset(distance.sign * 20, 0),
          timeStamp: const Duration(milliseconds: 100),
        );
        await gesture.moveBy(
          Offset(distance - distance.sign * 20, 0),
          timeStamp: const Duration(milliseconds: 600),
        );
        await tester.pump();
        final fraction = pages().page!;
        final expectedX =
            tester.getCenter(tab(0)).dx +
            fraction * tester.getSize(tab(0)).width;
        expect(tester.getCenter(indicator).dx, closeTo(expectedX, .1));
        expect(tester.getSize(indicator), tester.getSize(tab(0)));
        // Pause before releasing so this tests travel distance, not fling velocity.
        await gesture.moveBy(
          Offset.zero,
          timeStamp: const Duration(milliseconds: 1000),
        );
        await gesture.up(timeStamp: const Duration(milliseconds: 1100));
        await tester.pumpAndSettle();
      }

      await dragSlowly(-170); // Less than half the 390 px viewport.
      expect(pages().page, 1);
      await dragSlowly(170);
      expect(pages().page, 0);
      await dragSlowly(-85);
      expect(pages().page, 0);
      await dragSlowly(170); // First-page boundary.
      expect(pages().page, 0);
      await tester.tap(tab(3));
      await tester.pumpAndSettle();
      await dragSlowly(-170); // Last-page boundary.
      expect(pages().page, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Navigation pill moves through intermediate positions and follows rapid retargeting',
    (tester) async {
      await open(tester);
      final indicator = find.byKey(const ValueKey('nav-indicator'));
      final start = tester.getCenter(indicator).dx;
      await tester.tap(tab(3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final intermediate = tester.getCenter(indicator).dx;
      expect(intermediate, greaterThan(start));
      expect(intermediate, lessThan(tester.getCenter(tab(3)).dx));
      await tester.tap(tab(1));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(indicator).dx,
        closeTo(tester.getCenter(tab(1)).dx, .1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Chart opens editable day sheet; task changes update statistics and empty days can be filled',
    (tester) async {
      await planner.save(
        const Task(id: 'past', title: 'Вчерашняя', day: '2027-01-01'),
      );
      await open(tester);
      await tester.tap(tab(2));
      await tester.pumpAndSettle();
      final day = find.byKey(const ValueKey('chart-day-2027-01-01'));
      await tester.drag(
        find.byKey(const PageStorageKey('tab-scroll-2')),
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Месяц'));
      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();
      final today = find.byKey(const ValueKey('chart-day-2027-01-02'));
      expect(today.hitTestable(), findsOneWidget);
      expect(tester.getCenter(day).dx, lessThan(tester.getCenter(today).dx));
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('day-details-2027-01-01')),
        findsOneWidget,
      );
      await tester.tap(card('past'));
      await tester.pumpAndSettle();
      expect(planner.statistics.completed, 1);
      await tester.longPress(card('past'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Исправленная');
      await tester.ensureVisible(find.text('Сохранить изменения'));
      await tester.tap(find.text('Сохранить изменения'));
      await tester.pumpAndSettle();
      expect(find.text('Исправленная'), findsOneWidget);
      expect(planner.tasks.single.title, 'Исправленная');
      await tester.longPress(card('past'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Скопировать на сегодня'));
      await tester.pumpAndSettle();
      expect(planner.tasks.last.day, '2027-01-02');
      expect(planner.tasks.last.title, 'Исправленная');
      expect(planner.tasks.last.done, false);
      expect(planner.tasks.first.done, true);
      Navigator.of(
        tester.element(find.byKey(const ValueKey('day-details-2027-01-01'))),
      ).pop();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('chart-value-2027-01-01')))
            .data,
        '1',
      );
      final empty = find.byKey(const ValueKey('chart-day-2026-12-31'));
      await tester.tap(empty);
      await tester.pumpAndSettle();
      expect(find.text('На этот день задач нет.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('day-details-add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Добавлено в прошлое');
      final save = find.widgetWithText(DesignButton, 'Добавить задачу').last;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(planner.tasks.last.day, '2026-12-31');
      expect(planner.statistics.total, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Archive uses card tap and long-press actions too', (
    tester,
  ) async {
    await planner.save(
      const Task(id: 'past', title: 'Вчерашняя', day: '2027-01-01'),
    );
    await open(tester);
    await tester.tap(tab(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('archive-2027-01-01')));
    await tester.pumpAndSettle();
    await tester.tap(card('past'));
    await tester.pumpAndSettle();
    expect(planner.tasks.single.done, true);
    await tester.longPress(card('past'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Скопировать на сегодня'));
    await tester.pumpAndSettle();
    expect(planner.tasks.last.day, '2027-01-02');
    expect(planner.tasks.last.id, isNot('past'));
    await tester.longPress(card('past'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-delete')));
    await tester.pumpAndSettle();
    expect(planner.tasks.single.day, '2027-01-02');
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Задача удалена'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Задача удалена'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

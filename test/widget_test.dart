import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_todo/app.dart';
import 'package:daily_todo/core/calendar.dart';
import 'package:daily_todo/domain/entities/task.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/domain/usecases/manage_reminder.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'package:daily_todo/presentation/controllers/reminder_controller.dart';
import 'support/fakes.dart';

void main() {
  late PlannerController planner;
  late ReminderController reminder;
  late DateTime now;
  setUp(() async {
    now = DateTime(2026, 12, 31, 23, 59);
    planner = PlannerController(
      ManageTasks(MemoryTaskRepository()),
      clock: () => now,
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

  Future<void> open(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(DailyApp(planner: planner, reminder: reminder));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      final scrollable = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openDayMenu(WidgetTester tester) async {
    await reveal(tester, find.byKey(const ValueKey('day-selector')));
    await tester.tap(find.byKey(const ValueKey('day-selector')));
    await tester.pumpAndSettle();
  }

  Future<void> quickAdd(WidgetTester tester, String title) async {
    await reveal(tester, find.byKey(const ValueKey('quick-task')));
    await tester.enterText(find.byKey(const ValueKey('quick-task')), title);
    await tester.tap(find.byKey(const ValueKey('quick-add')));
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  }

  testWidgets('Date menu keeps today and tomorrow separate across midnight', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const ValueKey('day-tab-0')), findsNothing);
    await quickAdd(tester, 'Сегодняшний план');
    await openDayMenu(tester);
    await tester.tap(find.byKey(const ValueKey('tomorrow')));
    await tester.pumpAndSettle();
    expect(dayKey(planner.selected), '2027-01-01');
    expect(find.text('Сегодняшний план'), findsNothing);
    await quickAdd(tester, 'Завтрашний план');
    await openDayMenu(tester);
    await tester.tap(find.byKey(const ValueKey('today')));
    await tester.pumpAndSettle();
    expect(dayKey(planner.selected), '2026-12-31');
    expect(find.text('Завтрашний план'), findsNothing);
    expect(find.text('Сегодняшний план'), findsOneWidget);
    now = DateTime(2027, 1, 1);
    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();
    expect(dayKey(planner.selected), '2027-01-01');
    expect(find.text('Завтрашний план'), findsOneWidget);
    expect(planner.tasks, hasLength(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Repeated quick entry keeps keyboard available with sentence capitalization',
    (tester) async {
      await open(tester);
      final field = find.byKey(const ValueKey('quick-task'));
      await reveal(tester, field);
      await tester.showKeyboard(field);
      await tester.enterText(field, 'Первая задача');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(planner.tasks.single.title, 'Первая задача');
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, true);
      expect(tester.testTextInput.isVisible, true);
      await tester.enterText(field, 'Вторая задача');
      await tester.tap(find.byKey(const ValueKey('quick-add')));
      await tester.pumpAndSettle();
      expect(planner.tasks.map((task) => task.title), [
        'Первая задача',
        'Вторая задача',
      ]);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, true);
      expect(tester.testTextInput.isVisible, true);
      tester.testTextInput.hide();
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, true);
      expect(
        tester.widget<TextField>(field).textCapitalization,
        TextCapitalization.sentences,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Statistics switch counts and percentages and retain mode across tabs',
    (tester) async {
      for (final task in [
        const Task(id: '1', title: 'Первое', day: '2026-12-31', done: true),
        const Task(id: '2', title: 'Второе', day: '2026-12-31', done: true),
        const Task(id: '3', title: 'Третье', day: '2026-12-31'),
        const Task(id: '4', title: 'Четвёртое', day: '2026-12-31'),
        const Task(id: '5', title: 'Вчера', day: '2026-12-30', done: true),
        const Task(id: '6', title: 'Завтра', day: '2027-01-01', done: true),
      ]) {
        await planner.save(task);
      }
      await open(tester);
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      expect(find.text('Выполнено задач'), findsOneWidget);
      expect(find.text('из 5'), findsOneWidget);
      final todayValue = find.byKey(const ValueKey('chart-value-2026-12-31'));
      final yesterdayValue = find.byKey(
        const ValueKey('chart-value-2026-12-30'),
      );
      final todayBar = find.byKey(const ValueKey('chart-bar-2026-12-31'));
      final yesterdayBar = find.byKey(const ValueKey('chart-bar-2026-12-30'));
      expect(tester.widget<Text>(todayValue).data, '2');
      expect(tester.getSize(todayBar).height, 98);
      expect(tester.getSize(yesterdayBar).height, 49);
      await tester.tap(find.byTooltip('Настройки статистики'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Проценты'));
      await tester.pumpAndSettle();
      expect(find.text('Процент выполнения'), findsOneWidget);
      expect(tester.widget<Text>(todayValue).data, '50%');
      expect(tester.widget<Text>(yesterdayValue).data, '100%');
      expect(tester.getSize(todayBar).height, 49);
      expect(tester.getSize(yesterdayBar).height, 98);
      await tester.tap(find.text('Ачивки'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      expect(find.text('Процент выполнения'), findsOneWidget);
      await tester.tap(find.byTooltip('Настройки статистики'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Число задач'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(todayValue).data, '2');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Tomorrow, quick add, validation, completion, edit, deletion and undo',
    (tester) async {
      await open(tester);
      await openDayMenu(tester);
      await tester.tap(find.byKey(const ValueKey('tomorrow')));
      await tester.pumpAndSettle();
      await quickAdd(tester, '');
      expect(find.text('Напиши название задачи'), findsOneWidget);
      await quickAdd(tester, 'Прочитать 10 страниц');
      expect(planner.tasks.single.day, '2027-01-01');
      await reveal(
        tester,
        find.byKey(ValueKey('check-${planner.tasks.single.id}')),
      );
      await tester.tap(
        find.byKey(ValueKey('check-${planner.tasks.single.id}')),
      );
      await tester.pumpAndSettle();
      expect(planner.tasks.single.done, true);
      await tester.longPress(find.text('Прочитать 10 страниц'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Прочитать 20 страниц',
      );
      await reveal(tester, find.text('Сохранить изменения'));
      await tester.tap(find.text('Сохранить изменения'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Прочитать 20 страниц'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-delete')));
      await tester.pumpAndSettle();
      expect(planner.tasks, isEmpty);
      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle();
      expect(planner.tasks.single.title, 'Прочитать 20 страниц');
      expect(planner.tasks.single.done, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Arbitrary day and moving an existing task through the editor', (
    tester,
  ) async {
    await open(tester);
    await openDayMenu(tester);
    await tester.tap(find.byKey(const ValueKey('choose-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').first);
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(dayKey(planner.selected), '2026-12-15');
    await quickAdd(tester, 'На другую дату');
    await tester.longPress(find.text('На другую дату'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-edit')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('editor-date')));
    await tester.tap(find.byKey(const ValueKey('editor-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18').first);
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Сохранить изменения'));
    await tester.tap(find.text('Сохранить изменения'));
    await tester.pumpAndSettle();
    expect(planner.tasks.single.day, '2026-12-18');
    expect(dayKey(planner.selected), '2026-12-18');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Midnight, editable archive, four tabs and reminder in settings on narrow screens',
    (tester) async {
      await planner.save(
        Task(id: 'past', title: 'Последнее дело года', day: dayKey(now)),
      );
      await open(tester, width: 320);
      now = DateTime(2027, 1, 1);
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.text('Последнее дело года'), findsNothing);
      await tester.tap(find.text('Архив'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('archive-2026-12-31')));
      await tester.pumpAndSettle();
      expect(find.text('Последнее дело года'), findsOneWidget);
      await tester.tap(find.text('Открыть день'));
      await tester.pumpAndSettle();
      expect(dayKey(planner.selected), '2026-12-31');
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      expect(find.text('Последние 6 дней'), findsOneWidget);
      await tester.tap(find.text('Ачивки'));
      await tester.pumpAndSettle();
      expect(find.text('Открыто 0 из 13'), findsOneWidget);
      await tester.tap(find.text('Сегодня').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reminder-switch')), findsNothing);
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Вечернее напоминание'),
        180,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await tester.ensureVisible(
        find.widgetWithText(ListTile, 'Вечернее напоминание'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Вечернее напоминание'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(reminder.settings.enabled, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

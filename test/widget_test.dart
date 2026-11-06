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

  Future<void> openDayMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('day-selector')));
    await tester.pumpAndSettle();
  }

  Future<void> quickAdd(WidgetTester tester, String title) async {
    await tester.ensureVisible(find.byKey(const ValueKey('quick-task')));
    await tester.enterText(find.byKey(const ValueKey('quick-task')), title);
    await tester.tap(find.byKey(const ValueKey('quick-add')));
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  }

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
      await tester.ensureVisible(
        find.byKey(ValueKey('check-${planner.tasks.single.id}')),
      );
      await tester.tap(
        find.byKey(ValueKey('check-${planner.tasks.single.id}')),
      );
      await tester.pumpAndSettle();
      expect(planner.tasks.single.done, true);
      await tester.tap(find.text('Прочитать 10 страниц'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Прочитать 20 страниц',
      );
      await tester.ensureVisible(find.text('Сохранить изменения'));
      await tester.tap(find.text('Сохранить изменения'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Удалить'));
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
    await tester.tap(find.text('На другую дату'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('editor-date')));
    await tester.tap(find.byKey(const ValueKey('editor-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18').first);
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Сохранить изменения'));
    await tester.tap(find.text('Сохранить изменения'));
    await tester.pumpAndSettle();
    expect(planner.tasks.single.day, '2026-12-18');
    expect(dayKey(planner.selected), '2026-12-18');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Midnight, editable archive, four tabs and inline reminder on narrow screens',
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
      expect(find.text('Открыто 0 из 6'), findsOneWidget);
      await tester.tap(find.text('Сегодня'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reminder-switch')));
      await tester.pumpAndSettle();
      expect(reminder.settings.enabled, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

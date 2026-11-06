import 'package:flutter_test/flutter_test.dart';
import 'package:daily_todo/core/calendar.dart';
import 'package:daily_todo/domain/entities/task.dart';
import 'package:daily_todo/domain/entities/reminder_settings.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/domain/usecases/manage_reminder.dart';
import 'package:daily_todo/domain/usecases/task_statistics.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'package:daily_todo/presentation/controllers/reminder_controller.dart';
import 'package:daily_todo/data/services/local_reminder_scheduler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'support/fakes.dart';

void main() {
  test('Streak uses consecutive calendar days and ignores future plans', () {
    final tasks = [
      const Task(id: '1', title: 'Done', day: '2026-11-03', done: true),
      const Task(id: '2', title: 'Done', day: '2026-11-02', done: true),
      const Task(id: '3', title: 'Gap', day: '2026-11-01'),
      const Task(id: '4', title: 'Older', day: '2026-10-31', done: true),
      const Task(id: '5', title: 'Future', day: '2026-11-05', done: true),
    ];
    final statistics = TaskStatistics(tasks, DateTime(2026, 11, 4));
    expect(statistics.streak, 2);
    expect(statistics.awards[3].unlocked, false);
    final today = TaskStatistics([
      ...tasks,
      const Task(id: '6', title: 'Today', day: '2026-11-04', done: true),
    ], DateTime(2026, 11, 4));
    expect(today.streak, 3);
    expect(today.awards[3].unlocked, true);
  });
  test(
    'Dates cross month/year boundaries; switching midnight preserves a future selection',
    () async {
      var now = DateTime(2026, 12, 31, 23, 59);
      final planner = PlannerController(
        ManageTasks(MemoryTaskRepository()),
        clock: () => now,
      );
      await planner.initialize();
      expect(dayKey(nextDay(now)), '2027-01-01');
      now = DateTime(2027, 1, 1);
      planner.refreshDate();
      expect(planner.selected, DateTime(2027, 1, 1));
      planner.select(DateTime(2027, 1, 5));
      now = DateTime(2027, 1, 2);
      planner.refreshDate();
      expect(planner.selected, DateTime(2027, 1, 5));
      planner.dispose();
    },
  );

  test(
    'Save validates and failed writes/deletes leave controller unchanged',
    () async {
      final repository = MemoryTaskRepository();
      final actions = ManageTasks(repository);
      final planner = PlannerController(actions);
      await planner.initialize();
      const task = Task(id: 'a', title: '  Read  ', day: '2026-11-04');
      await planner.save(task);
      expect(planner.tasks.single.title, 'Read');
      expect(
        () => actions.save(task.copyWith(title: ' ')),
        throwsArgumentError,
      );
      expect(
        () => actions.save(task.copyWith(day: '2026-02-30')),
        throwsArgumentError,
      );
      repository.fail = true;
      await expectLater(
        planner.save(task.copyWith(done: true)),
        throwsStateError,
      );
      await expectLater(planner.delete(task), throwsStateError);
      expect(planner.tasks.single.done, false);
      expect(planner.busy, false);
      planner.dispose();
    },
  );

  test(
    'Statistics exclude future tasks and achievements follow current data',
    () {
      final stats = TaskStatistics([
        const Task(id: '1', title: 'Past', day: '2026-11-03', done: true),
        const Task(id: '2', title: 'Today', day: '2026-11-04'),
        const Task(id: '3', title: 'Future', day: '2026-11-05', done: true),
      ], DateTime(2026, 11, 4));
      expect(stats.total, 2);
      expect(stats.percent, 50);
      expect(stats.perfectDays, 1);
      expect(stats.achievements, [true, false, true, false]);
      expect(stats.week.last.total, 1);
    },
  );

  test(
    'Reminder defaults, denial, scheduling, time change, cancellation and reopen',
    () async {
      final repository = MemoryReminderRepository();
      final scheduler = FakeScheduler();
      final actions = ManageReminder(repository, scheduler);
      final controller = ReminderController(actions);
      await controller.initialize();
      expect(scheduler.requests, 0);
      expect(controller.settings.hour, 21);
      expect(controller.settings.minute, 30);
      scheduler.granted = false;
      await controller.update(controller.settings.copyWith(enabled: true));
      expect(controller.settings.enabled, false);
      expect(controller.error, contains('Разрешите'));
      expect(scheduler.scheduled, isNull);
      scheduler.granted = true;
      await controller.update(controller.settings.copyWith(enabled: true));
      await controller.update(
        controller.settings.copyWith(hour: 22, minute: 0),
      );
      expect(scheduler.scheduled!.hour, 22);
      final reopened = ReminderController(actions);
      await reopened.initialize();
      expect(reopened.settings.enabled, true);
      expect(reopened.settings.hour, 22);
      await reopened.update(reopened.settings.copyWith(enabled: false));
      expect(scheduler.scheduled, isNull);
      expect(repository.settings.enabled, false);
      controller.dispose();
      reopened.dispose();
    },
  );

  test(
    'Reminder restores previous schedule when persistence or scheduler fails',
    () async {
      final repository = MemoryReminderRepository();
      final scheduler = FakeScheduler();
      final actions = ManageReminder(repository, scheduler);
      const previous = ReminderSettings(enabled: true);
      await actions.update(const ReminderSettings(), previous);
      repository.fail = true;
      await expectLater(
        actions.update(previous, previous.copyWith(hour: 22)),
        throwsStateError,
      );
      expect(scheduler.scheduled!.hour, 21);
      expect(repository.settings.hour, 21);
      repository.fail = false;
      scheduler.fail = true;
      await expectLater(
        actions.update(previous, previous.copyWith(hour: 22)),
        throwsStateError,
      );
      expect(repository.settings.hour, 21);
    },
  );

  test(
    'Next reminder uses local calendar time, including DST and next day',
    () {
      tz_data.initializeTimeZones();
      final zone = tz.getLocation('Europe/Berlin');
      final now = tz.TZDateTime(zone, 2026, 3, 28, 22);
      final next = nextReminder(now, 21, 30);
      expect(next.day, 29);
      expect(next.hour, 21);
      expect(next.timeZoneOffset, const Duration(hours: 2));
      expect(
        nextReminder(tz.TZDateTime(zone, 2026, 12, 31, 21, 30), 21, 30).year,
        2027,
      );
    },
  );
}

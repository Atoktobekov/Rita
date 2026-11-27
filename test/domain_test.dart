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
  TaskAward award(List<Task> tasks, String title, {DateTime? today}) =>
      TaskStatistics(
        tasks,
        today ?? DateTime(2027, 2, 1),
      ).awards.singleWhere((a) => a.title == title);

  List<Task> daily(int count, {int step = 1, bool half = false}) => [
    for (var i = 0; i < count; i++) ...[
      Task(
        id: 'done-$i',
        title: 'Готово',
        day: dayKey(DateTime(2027, 1, 1 + i * step)),
        done: true,
      ),
      if (half)
        Task(
          id: 'pending-$i',
          title: 'План',
          day: dayKey(DateTime(2027, 1, 1 + i * step)),
        ),
    ],
  ];

  test('All completion thresholds ignore future and unfinished tasks', () {
    for (final (title, threshold) in [
      ('Первоход', 1),
      ('Червонец', 10),
      ('Четвертак', 25),
      ('Пять по десять', 50),
      ('Легенда', 100),
      ('Бонаква', 250),
    ]) {
      final tasks = [
        for (var i = 0; i < threshold - 1; i++)
          Task(id: '$i', title: 'Готово', day: '2027-01-01', done: true),
        const Task(id: 'future', title: 'Потом', day: '2027-02-02', done: true),
        const Task(id: 'pending', title: 'План', day: '2027-01-01'),
      ];
      expect(award(tasks, title).unlocked, false, reason: title);
      tasks.add(
        const Task(id: 'last', title: 'Готово', day: '2027-01-01', done: true),
      );
      expect(award(tasks, title).unlocked, true, reason: title);
      tasks[tasks.length - 1] = tasks.last.copyWith(done: false);
      expect(award(tasks, title).unlocked, false, reason: title);
    }
    expect(TaskStatistics([], DateTime(2027, 2, 1)).awards, hasLength(13));
  });

  test('Half-complete totals differ from consecutive series', () {
    expect(award(daily(2, half: true), 'Ты у меня третий').unlocked, false);
    expect(award(daily(3, half: true), 'Ты у меня третий').unlocked, true);
    expect(
      award(daily(3, half: true, step: 2), 'Ты у меня третий').unlocked,
      false,
    );
    for (final (title, count) in [('Жигули', 7), ('Эпштейн', 14)]) {
      expect(
        award(daily(count - 1, half: true, step: 2), title).unlocked,
        false,
      );
      final tasks = daily(count, half: true, step: 2);
      expect(award(tasks, title).unlocked, true);
      tasks.add(const Task(id: 'extra', title: 'Ещё', day: '2027-01-01'));
      expect(award(tasks, title).unlocked, false);
    }
  });

  test(
    'Perfect awards require nonempty days and uninterrupted calendar series',
    () {
      expect(award([], 'Эйс').unlocked, false);
      expect(award(daily(1), 'Эйс').unlocked, true);
      for (final (title, count) in [('Бешке бир', 5), ('Тайная вечеря', 13)]) {
        expect(award(daily(count - 1), title).unlocked, false);
        expect(award(daily(count), title).unlocked, true);
        expect(award(daily(count, step: 2), title).unlocked, false);
        expect(award(daily(count, half: true), title).unlocked, false);
        final tasks = daily(count)
          ..add(const Task(id: 'gap', title: 'Не сделано', day: '2027-01-03'));
        expect(award(tasks, title).unlocked, false);
      }
    },
  );

  test(
    'Historical streak survives later missed days and crosses year boundaries',
    () {
      final tasks = [
        for (var i = 0; i < 5; i++)
          Task(
            id: '$i',
            title: 'Да',
            day: dayKey(DateTime(2026, 12, 29 + i)),
            done: true,
          ),
        const Task(id: 'missed', title: 'Нет', day: '2027-01-03'),
      ];
      final stats = TaskStatistics(tasks, DateTime(2027, 1, 4));
      expect(stats.streak, 0);
      expect(stats.longestPerfectStreak, 5);
      expect(award(tasks, 'Бешке бир').unlocked, true);
      final throughYesterday = TaskStatistics(
        tasks.take(5).toList(),
        DateTime(2027, 1, 3),
      );
      expect(throughYesterday.streak, 5);
    },
  );

  test(
    'NNN counts completed days from first task, empty days and interruptions',
    () {
      const first = Task(id: 'first', title: 'План', day: '2027-01-01');
      expect(award([], 'NNN').unlocked, false);
      expect(
        award([first], 'NNN', today: DateTime(2027, 1, 30)).unlocked,
        false,
      );
      expect(
        award([first], 'NNN', today: DateTime(2027, 1, 31)).unlocked,
        true,
      );
      expect(
        award([
          first,
          const Task(
            id: 'done',
            title: 'Готово',
            day: '2027-01-15',
            done: true,
          ),
        ], 'NNN').unlocked,
        false,
      );
      expect(
        award(
          [
            first,
            const Task(
              id: 'today',
              title: 'Готово',
              day: '2027-01-31',
              done: true,
            ),
          ],
          'NNN',
          today: DateTime(2027, 1, 31),
        ).unlocked,
        true,
      );
    },
  );

  test(
    'Secret award matches Russian word forms, is hidden until completion and ignores future',
    () {
      bool visible(
        String title, {
        bool done = true,
        String day = '2027-01-01',
      }) => TaskStatistics([
        Task(id: '1', title: title, day: day, done: done),
      ], DateTime(2027, 2, 1)).awards.any((a) => a.title == 'Дрочер');
      for (final title in [
        'дрочить',
        'Подрочить!',
        'ДРОЧКА',
        'мастурбация',
        'онанизм',
        'Заняться мастурбацией',
        'мастурбировать',
        'онанировать',
        'подрочил',
      ]) {
        expect(visible(title), true, reason: title);
      }
      for (final title in ['Прочитать', 'Командировка', 'Подрочник', 'спорт']) {
        expect(visible(title), false, reason: title);
      }
      expect(visible('дрочить', done: false), false);
      expect(visible('дрочить', day: '2027-02-02'), false);
    },
  );

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
      expect(stats.awards.first.unlocked, true);
      expect(stats.awards[3].unlocked, true);
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

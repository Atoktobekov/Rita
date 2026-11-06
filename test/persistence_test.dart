import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:daily_todo/data/repositories/hive_task_repository.dart';
import 'package:daily_todo/data/repositories/hive_reminder_repository.dart';
import 'package:daily_todo/domain/entities/reminder_settings.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('daily_v02_');
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'Version 0.1 records reopen without migration; moving a task keeps its identity',
    () async {
      var box = await Hive.openBox<dynamic>('tasks_v1');
      await box.put('legacy', {
        'id': 'legacy',
        'title': 'Старая задача',
        'day': '2026-11-04',
        'category': 'Работа',
        'done': true,
      });
      var repository = HiveTaskRepository(box);
      final task = (await repository.load()).single;
      await repository.save(task.copyWith(day: '2026-11-05'));
      await box.close();
      box = await Hive.openBox<dynamic>('tasks_v1');
      repository = HiveTaskRepository(box);
      final reopened = (await repository.load()).single;
      expect(reopened.id, 'legacy');
      expect(reopened.day, '2026-11-05');
      expect(reopened.category, 'Работа');
      expect(reopened.done, true);
      await repository.delete(reopened.id);
      expect(await repository.load(), isEmpty);
    },
  );

  test('Reminder settings survive a real Hive reopen', () async {
    var box = await Hive.openBox<dynamic>('settings_v1');
    await HiveReminderRepository(
      box,
    ).save(const ReminderSettings(enabled: true, hour: 22, minute: 15));
    await box.close();
    box = await Hive.openBox<dynamic>('settings_v1');
    final settings = await HiveReminderRepository(box).load();
    expect(settings.enabled, true);
    expect(settings.hour, 22);
    expect(settings.minute, 15);
  });
}

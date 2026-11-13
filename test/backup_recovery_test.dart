import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:daily_todo/data/models/task_record.dart';
import 'package:daily_todo/data/repositories/hive_task_repository.dart';
import 'package:daily_todo/data/services/task_backup.dart';
import 'package:daily_todo/domain/entities/task.dart';

class FailingBox extends Fake implements Box<dynamic> {
  FailingBox(this.delegate);
  final Box<dynamic> delegate;
  bool fail = false;
  @override
  bool containsKey(dynamic key) => delegate.containsKey(key);
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      delegate.get(key, defaultValue: defaultValue);
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail) throw const FileSystemException('disk full');
    await delegate.put(key, value);
  }
}

void main() {
  const old = Task(
    id: 'old',
    title: 'Старая задача',
    day: '2026-12-31',
    category: 'Работа',
    done: true,
  );
  const next = Task(id: 'next', title: 'Новый план', day: '2027-01-01');
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('daily_recovery_');
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('Portable backup round trips every task field', () {
    final now = DateTime.utc(2026, 12, 31, 20);
    final copy = TaskBackup.decode(TaskBackup.encode([old, next], now));
    expect(copy.createdAt, now);
    expect(copy.tasks.map(TaskRecord.encode), [
      TaskRecord.encode(old),
      TaskRecord.encode(next),
    ]);
  });

  test(
    'Import rejects unsupported versions, duplicates, malformed fields and oversized files',
    () {
      Map<String, dynamic> valid() =>
          jsonDecode(utf8.decode(TaskBackup.encode([old], DateTime.now())))
              as Map<String, dynamic>;
      for (final record in [
        {...valid(), 'version': 99},
        {
          ...valid(),
          'tasks': [TaskRecord.encode(old), TaskRecord.encode(old)],
        },
        {
          ...valid(),
          'tasks': [
            {...TaskRecord.encode(old), 'day': '2026-02-30'},
          ],
        },
        {
          ...valid(),
          'tasks': [
            {...TaskRecord.encode(old), 'title': '   '},
          ],
        },
        {
          ...valid(),
          'tasks': [
            {...TaskRecord.encode(old), 'done': 'true'},
          ],
        },
        {
          ...valid(),
          'tasks': [
            {...TaskRecord.encode(old), 'category': 42},
          ],
        },
        {...valid(), 'createdAt': 'invalid'},
      ]) {
        expect(
          () => TaskBackup.decode(utf8.encode(jsonEncode(record))),
          throwsFormatException,
        );
      }
      expect(() => TaskBackup.decode([0xff]), throwsFormatException);
      expect(() => TaskBackup.decode(utf8.encode('{')), throwsFormatException);
      expect(
        () => TaskBackup.decode(List.filled(TaskBackup.maxBytes + 1, 32)),
        throwsFormatException,
      );
      expect(
        TaskBackup.decode(TaskBackup.encode([], DateTime.now())).tasks,
        isEmpty,
      );
    },
  );

  test(
    'Bad legacy rows are retained separately and healthy tasks survive reopen',
    () async {
      final legacy = await Hive.openBox<dynamic>('tasks_v1');
      final broken = {'id': 'broken', 'title': 123, 'day': 'bad'};
      await legacy.putAll({
        'old': TaskRecord.encode(old),
        'broken': broken,
        'bad-day': {
          ...TaskRecord.encode(next),
          'id': 'bad-day',
          'day': '2026-02-30',
        },
      });
      var box = await Hive.openBox<dynamic>('tasks_v2');
      var repository = HiveTaskRepository(box, legacyBox: legacy);
      final initial = await repository.load();
      expect(initial.tasks.single.id, 'old');
      expect(initial.damagedCount, 2);
      expect(legacy.get('broken'), broken);
      expect(
        (box.get('state')['rejected'] as List).singleWhere(
          (row) => row['key'] == 'broken',
        )['value'],
        broken,
      );
      await repository.save(next);
      await box.close();
      box = await Hive.openBox<dynamic>('tasks_v2');
      repository = HiveTaskRepository(box, legacyBox: legacy);
      final reopened = await repository.load();
      expect(reopened.tasks.map((t) => t.id), ['old', 'next']);
      expect(reopened.damagedCount, 2);
      await repository.replaceAll([], createBackup: true);
      expect((await repository.load()).damagedCount, 2);
      expect((await repository.restoreBackup()).tasks, hasLength(2));
    },
  );

  test(
    'Import and its backup commit together and restoration survives restart',
    () async {
      var box = await Hive.openBox<dynamic>('tasks_v2');
      final failing = FailingBox(box);
      final repository = HiveTaskRepository(failing);
      await repository.load();
      await repository.save(old);
      failing.fail = true;
      expect((await repository.load()).tasks.single.id, 'old');
      await expectLater(
        repository.replaceAll([next], createBackup: true),
        throwsA(isA<FileSystemException>()),
      );
      expect((box.get('state')['tasks'] as Map).keys, ['old']);
      expect(box.get('state')['backup'], isNull);
      failing.fail = false;
      await repository.replaceAll([next], createBackup: true);
      await box.close();
      box = await Hive.openBox<dynamic>('tasks_v2');
      final reopened = HiveTaskRepository(box);
      expect((await reopened.load()).tasks.single.id, 'next');
      expect((await reopened.restoreBackup()).tasks.single.id, 'old');
      await box.close();
      box = await Hive.openBox<dynamic>('tasks_v2');
      final again = HiveTaskRepository(box);
      expect((await again.load()).tasks.single.id, 'old');
      expect((await again.restoreBackup()).tasks.single.id, 'next');
    },
  );

  test(
    'Broken active rows are quarantined, malformed envelope is never replaced',
    () async {
      final box = await Hive.openBox<dynamic>('tasks_v2');
      await box.put('state', {
        'version': 2,
        'tasks': {'old': TaskRecord.encode(old), 'bad': null},
        'rejected': [],
        'backup': null,
      });
      final result = await HiveTaskRepository(box).load();
      expect(result.tasks.single.id, 'old');
      expect(result.damagedCount, 1);
      final invalid = {'version': 42, 'tasks': 'broken'};
      await box.put('state', invalid);
      await expectLater(HiveTaskRepository(box).load(), throwsFormatException);
      expect(box.get('state'), invalid);
      await box.put('state', null);
      await expectLater(HiveTaskRepository(box).load(), throwsFormatException);
      expect(box.containsKey('state'), true);
    },
  );
}

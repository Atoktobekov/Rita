import 'package:hive_ce/hive.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_snapshot.dart';
import '../../domain/entities/task_validation.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_record.dart';

/// A whole collection and its recovery copy are one Hive value. A failed write
/// cannot publish half an import or half a multi-task move.
class HiveTaskRepository implements TaskRepository {
  HiveTaskRepository(this.box, {this.legacyBox});
  final Box<dynamic> box;
  final Box<dynamic>? legacyBox;
  Map<String, dynamic>? _state;
  bool _writing = false;

  Map<String, dynamic> _normalize(dynamic value) {
    if (value is! Map || value['tasks'] is! Map || value['rejected'] is! List) {
      throw const FormatException('Не удалось прочитать хранилище задач');
    }
    final tasks = <String, dynamic>{};
    final rejected = List<dynamic>.of(value['rejected'] as List);
    for (final entry in (value['tasks'] as Map).entries) {
      try {
        final task = TaskRecord.decode(entry.value);
        if (entry.key != task.id) {
          throw const FormatException(
            'Идентификатор не совпадает с ключом записи',
          );
        }
        tasks[task.id] = TaskRecord.encode(task);
      } on FormatException catch (error) {
        rejected.add({
          'key': entry.key,
          'value': entry.value,
          'reason': error.message,
        });
      }
    }
    return {'tasks': tasks, 'rejected': rejected};
  }

  @override
  Future<TaskSnapshot> load() async {
    final raw = box.get('state');
    if (raw == null && box.containsKey('state')) {
      throw const FormatException('Повреждён основной снимок задач');
    }
    final Map<String, dynamic> next;
    if (raw == null) {
      next = {
        'version': 2,
        ..._normalize({'tasks': legacyBox?.toMap() ?? {}, 'rejected': []}),
        'backup': null,
      };
    } else {
      if (raw is! Map || raw['version'] != 2) {
        throw const FormatException('Неизвестная версия хранилища задач');
      }
      next = {
        'version': 2,
        ..._normalize(raw),
        'backup': raw['backup'] == null ? null : _normalize(raw['backup']),
      };
    }
    // Keeps malformed records separately, including their original values.
    // The legacy box is never changed.
    if (raw == null ||
        (next['rejected'] as List).length != (raw['rejected'] as List).length ||
        (next['backup'] != null &&
            (next['backup']['rejected'] as List).length !=
                (raw['backup']['rejected'] as List).length)) {
      await _commit(next);
    } else {
      _state = next;
    }
    return TaskSnapshot(
      (next['tasks'] as Map).values.map(TaskRecord.decode),
      damagedCount: (next['rejected'] as List).length,
      canRestore: next['backup'] != null,
    );
  }

  Map<String, dynamic> get _current =>
      _state ?? (throw StateError('Сначала загрузите задачи'));

  Future<void> _commit(Map<String, dynamic> next) async {
    if (_writing) throw StateError('Сохранение уже выполняется');
    _writing = true;
    try {
      await box.put('state', next);
      _state = next;
    } finally {
      _writing = false;
    }
  }

  @override
  Future<void> save(Task task) {
    validateTask(task);
    return _commit({
      ..._current,
      'tasks': {..._current['tasks'] as Map, task.id: TaskRecord.encode(task)},
    });
  }

  @override
  Future<void> delete(String id) {
    final tasks = Map<dynamic, dynamic>.of(_current['tasks'] as Map)
      ..remove(id);
    return _commit({..._current, 'tasks': tasks});
  }

  @override
  Future<void> replaceAll(List<Task> tasks, {bool createBackup = false}) {
    validateTasks(tasks);
    return _commit({
      ..._current,
      'tasks': {for (final task in tasks) task.id: TaskRecord.encode(task)},
      if (createBackup)
        'backup': {
          'tasks': _current['tasks'],
          'rejected': _current['rejected'],
        },
    });
  }

  @override
  Future<TaskSnapshot> restoreBackup() async {
    final backup = _current['backup'];
    if (backup is! Map) throw StateError('Нет предыдущей копии');
    final next = {
      'version': 2,
      ..._normalize(backup),
      'backup': {'tasks': _current['tasks'], 'rejected': _current['rejected']},
    };
    await _commit(next);
    return TaskSnapshot(
      (next['tasks'] as Map).values.map(TaskRecord.decode),
      damagedCount: (next['rejected'] as List).length,
      canRestore: true,
    );
  }
}

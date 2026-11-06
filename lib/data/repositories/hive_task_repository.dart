import 'package:hive_ce/hive.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_record.dart';

class HiveTaskRepository implements TaskRepository {
  const HiveTaskRepository(this.box);
  final Box<dynamic> box;

  @override
  Future<List<Task>> load() async => box.values.map(TaskRecord.decode).toList();
  @override
  Future<void> save(Task task) => box.put(task.id, TaskRecord.encode(task));
  @override
  Future<void> delete(String id) => box.delete(id);
}

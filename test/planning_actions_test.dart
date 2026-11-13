import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_todo/domain/entities/task.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'support/fakes.dart';

class SlowRepository extends MemoryTaskRepository {
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> replaceAll(List<Task> tasks, {bool createBackup = false}) async {
    started.complete();
    await release.future;
    await super.replaceAll(tasks, createBackup: createBackup);
  }
}

void main() {
  const task = Task(id: 'pending', title: 'План', day: '2026-12-31');
  test(
    'Move only unfinished selected-day tasks across year and undo without losing other changes',
    () async {
      final repository = MemoryTaskRepository();
      final planner = PlannerController(
        ManageTasks(repository),
        clock: () => DateTime(2026, 12, 31),
      );
      addTearDown(planner.dispose);
      await planner.initialize();
      await planner.save(task);
      await planner.save(
        const Task(id: 'done', title: 'Готово', day: '2026-12-31', done: true),
      );
      await planner.save(
        const Task(id: 'future', title: 'Потом', day: '2027-01-02'),
      );
      final move = await planner.moveUnfinishedToTomorrow();
      expect(move.tasks.single.id, 'pending');
      expect(planner.tasks.first.day, '2027-01-01');
      expect(planner.tasks[1].day, '2026-12-31');
      expect(planner.futureDays, ['2027-01-01', '2027-01-02']);
      await planner.save(
        const Task(id: 'extra', title: 'Ещё', day: '2027-01-01'),
      );
      await planner.undoMove(move);
      expect(planner.tasks.first.day, '2026-12-31');
      expect(planner.tasks.last.id, 'extra');
      final second = await planner.moveUnfinishedToTomorrow();
      await planner.save(planner.tasks.first.copyWith(done: true));
      await expectLater(planner.undoMove(second), throwsStateError);
      expect(planner.tasks.first.done, true);
      expect(planner.tasks.first.day, '2027-01-01');
    },
  );

  test(
    'Failed import or move leaves the visible plan and backup flag unchanged',
    () async {
      final repository = MemoryTaskRepository();
      final planner = PlannerController(
        ManageTasks(repository),
        clock: () => DateTime(2026, 12, 31),
      );
      addTearDown(planner.dispose);
      await planner.initialize();
      await planner.save(task);
      repository.fail = true;
      await expectLater(planner.moveUnfinishedToTomorrow(), throwsStateError);
      await expectLater(planner.importTasks([]), throwsStateError);
      expect(planner.tasks.single.day, '2026-12-31');
      expect(planner.canRestore, false);
      expect(planner.busy, false);
      repository.fail = false;
      await planner.importTasks([]);
      expect(planner.tasks, isEmpty);
      expect(planner.canRestore, true);
      await planner.restoreBackup();
      expect(planner.tasks.single.id, 'pending');
    },
  );

  test(
    'Batch writes serialize concurrent edits and publish only after persistence',
    () async {
      final repository = SlowRepository();
      final planner = PlannerController(
        ManageTasks(repository),
        clock: () => DateTime(2026, 12, 31),
      );
      addTearDown(planner.dispose);
      await planner.initialize();
      await planner.save(task);
      final move = planner.moveUnfinishedToTomorrow();
      await repository.started.future;
      expect(planner.busy, true);
      expect(planner.tasks.single.day, '2026-12-31');
      await expectLater(
        planner.save(task.copyWith(done: true)),
        throwsStateError,
      );
      repository.release.complete();
      await move;
      expect(planner.busy, false);
      expect(planner.tasks.single.day, '2027-01-01');
    },
  );
}

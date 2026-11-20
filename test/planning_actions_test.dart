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
    'Copy unfinished tasks across year, preserve statistics and safely undo',
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
      final move = await planner.copyUnfinishedToTomorrow();
      expect(move.tasks.single.id, isNot('pending'));
      expect(move.tasks.single.day, '2027-01-01');
      expect(planner.tasks.first.day, '2026-12-31');
      expect(planner.statistics.percent, 50);
      expect(planner.tasks, hasLength(4));
      expect(planner.tasks[1].day, '2026-12-31');
      expect(planner.futureDays, ['2027-01-01', '2027-01-02']);
      await planner.save(
        const Task(id: 'extra', title: 'Ещё', day: '2027-01-01'),
      );
      await planner.undoCopy(move);
      expect(planner.tasks.first.day, '2026-12-31');
      expect(planner.tasks.last.id, 'extra');
      final second = await planner.copyUnfinishedToTomorrow();
      await planner.save(second.tasks.single.copyWith(done: true));
      await expectLater(planner.undoCopy(second), throwsStateError);
      expect(planner.tasks.first.done, false);
      expect(planner.tasks.first.day, '2026-12-31');
      expect(planner.tasks.last.done, true);
      expect(planner.statistics.percent, 50);
    },
  );

  test(
    'Failed import or copy leaves the visible plan and backup flag unchanged',
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
      await expectLater(planner.copyUnfinishedToTomorrow(), throwsStateError);
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
      final move = planner.copyUnfinishedToTomorrow();
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
      expect(planner.tasks, hasLength(2));
      expect(planner.tasks.first.day, '2026-12-31');
      expect(planner.tasks.last.day, '2027-01-01');
    },
  );
  test(
    'Copies over several days keep every missed day in the statistics',
    () async {
      var now = DateTime(2026, 12, 31);
      final repository = MemoryTaskRepository();
      final planner = PlannerController(
        ManageTasks(repository),
        clock: () => now,
      );
      addTearDown(planner.dispose);
      await planner.initialize();
      await planner.save(task);
      await planner.copyUnfinishedToTomorrow();
      now = DateTime(2027, 1, 1);
      planner.refreshDate();
      await planner.copyUnfinishedToTomorrow();
      now = DateTime(2027, 1, 2);
      planner.refreshDate();
      await planner.save(planner.selectedTasks.single.copyWith(done: true));
      expect(planner.tasks.map((t) => t.id).toSet(), hasLength(3));
      expect(planner.statistics.total, 3);
      expect(planner.statistics.completed, 1);
      expect(planner.statistics.percent, 33);
      final reopened = PlannerController(
        ManageTasks(repository),
        clock: () => now,
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.statistics.percent, 33);
    },
  );
}

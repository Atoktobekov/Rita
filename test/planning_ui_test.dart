import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_todo/app.dart';
import 'package:daily_todo/data/services/backup_files.dart';
import 'package:daily_todo/data/services/task_backup.dart';
import 'package:daily_todo/domain/entities/task.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/domain/usecases/manage_reminder.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'package:daily_todo/presentation/controllers/reminder_controller.dart';
import 'package:daily_todo/presentation/pages/backup_page.dart';
import 'package:daily_todo/presentation/widgets/task_card.dart';
import 'package:daily_todo/presentation/widgets/task_editor.dart';
import 'support/fakes.dart';

class SelectedBackup extends BackupFiles {
  TaskBackup? selection;
  bool invalid = false;
  List<Task>? exported;

  @override
  Future<TaskBackup?> pick() async {
    if (invalid) throw const FormatException('Некорректная копия');
    return selection;
  }

  @override
  Future<bool> save(List<Task> tasks) async {
    exported = tasks;
    return true;
  }
}

void main() {
  late MemoryTaskRepository repository;
  late PlannerController planner;
  late ReminderController reminder;
  setUp(() async {
    repository = MemoryTaskRepository();
    planner = PlannerController(
      ManageTasks(repository),
      clock: () => DateTime(2026, 12, 31),
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

  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Editor retains title and legacy data after failed save and retries',
    (tester) async {
      await planner.save(
        const Task(
          id: 'a',
          title: 'Исходная задача',
          day: '2026-12-31',
          category: 'Работа',
        ),
      );
      await open(tester);
      await reveal(tester, find.text('Исходная задача'));
      await tester.longPress(find.text('Исходная задача'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('task-edit')));
      await tester.enterText(find.byType(TextFormField), 'Исправленный текст');
      expect(find.byType(ChoiceChip), findsNothing);
      repository.fail = true;
      await tapVisible(tester, find.text('Сохранить изменения'));
      expect(find.byType(TaskEditor), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Исправленный текст',
      );
      expect(find.textContaining('Текст сохранён в форме'), findsOneWidget);
      expect(planner.tasks.single.title, 'Исходная задача');
      repository.fail = false;
      await tapVisible(tester, find.text('Сохранить изменения'));
      expect(find.byType(TaskEditor), findsNothing);
      expect(planner.tasks.single.title, 'Исправленный текст');
      expect(planner.tasks.single.category, 'Работа');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Tasks without categories, tomorrow move, undo and future overview are usable',
    (tester) async {
      await planner.save(
        const Task(
          id: 'a',
          title: 'Рабочая задача',
          day: '2026-12-31',
          category: 'Работа',
        ),
      );
      await planner.save(
        const Task(id: 'b', title: 'Личная задача', day: '2026-12-31'),
      );
      await open(tester);
      expect(find.byTooltip('Категория задач'), findsNothing);
      expect(find.text('Работа'), findsNothing);
      await reveal(tester, find.widgetWithText(TaskCard, 'Личная задача'));
      expect(find.widgetWithText(TaskCard, 'Рабочая задача'), findsOneWidget);
      expect(find.widgetWithText(TaskCard, 'Личная задача'), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('move-unfinished')));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('move-unfinished'))).dy,
        greaterThan(
          tester
              .getBottomLeft(find.widgetWithText(TaskCard, 'Личная задача'))
              .dy,
        ),
      );
      await tapVisible(tester, find.byKey(const ValueKey('move-unfinished')));
      expect(planner.tasks.where((t) => t.day == '2027-01-01'), hasLength(2));
      expect(planner.tasks.where((t) => t.day == '2026-12-31'), hasLength(2));
      await tapVisible(tester, find.text('Отменить'));
      expect(planner.tasks.every((t) => t.day == '2026-12-31'), true);
      await tapVisible(tester, find.byKey(const ValueKey('move-unfinished')));
      await tapVisible(tester, find.byTooltip('Будущие планы'));
      await tapVisible(tester, find.text('1 января 2027'));
      expect(planner.selected, DateTime(2027, 1, 1));
      await reveal(tester, find.widgetWithText(TaskCard, 'Личная задача'));
      expect(find.widgetWithText(TaskCard, 'Личная задача'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Import requires preview and confirmation; failed import is retryable and backup restores',
    (tester) async {
      await planner.save(
        const Task(id: 'a', title: 'Текущая', day: '2026-12-31'),
      );
      final files = SelectedBackup()
        ..selection = TaskBackup([
          const Task(id: 'b', title: 'Из копии', day: '2027-01-01'),
        ], DateTime.utc(2026, 12, 1));
      await open(tester);
      final context = tester.element(find.byType(Scaffold).first);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BackupPage(planner: planner, files: files),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Выбрать файл для импорта'));
      expect(find.text('Предпросмотр копии'), findsOneWidget);
      expect(planner.tasks.single.id, 'a');
      await tapVisible(tester, find.byKey(const ValueKey('apply-import')));
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(planner.tasks.single.id, 'a');
      repository.fail = true;
      await tapVisible(tester, find.byKey(const ValueKey('apply-import')));
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      expect(planner.tasks.single.id, 'a');
      expect(find.text('Предпросмотр копии'), findsOneWidget);
      repository.fail = false;
      await tapVisible(tester, find.byKey(const ValueKey('apply-import')));
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      expect(planner.tasks.single.id, 'b');
      await tapVisible(tester, find.text('Восстановить предыдущую версию'));
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      expect(planner.tasks.single.id, 'a');
      files.invalid = true;
      await tapVisible(tester, find.text('Выбрать файл для импорта'));
      expect(find.text('Некорректная копия'), findsOneWidget);
      expect(planner.tasks.single.id, 'a');
      await tapVisible(tester, find.text('Экспортировать задачи (1)'));
      expect(files.exported!.single.id, 'a');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Large system text on narrow screens and 48 pixel task targets', (
    tester,
  ) async {
    await planner.save(
      const Task(
        id: 'a',
        title: 'Длинное название задачи для проверки доступности',
        day: '2026-12-31',
      ),
    );
    await open(tester, scale: 2);
    await reveal(tester, find.byKey(const ValueKey('check-a')));
    await tester.pumpAndSettle();
    final size = tester.getSize(find.byKey(const ValueKey('check-a')));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.longPress(find.byKey(const ValueKey('check-a')));
    await tester.pumpAndSettle();
    final deleteSize = tester.getSize(
      find.byKey(const ValueKey('task-delete')),
    );
    expect(deleteSize.width, greaterThanOrEqualTo(48));
    expect(deleteSize.height, greaterThanOrEqualTo(48));
    Navigator.of(
      tester.element(find.byKey(const ValueKey('task-delete'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final tab in ['Архив', 'Статистика', 'Ачивки', 'Сегодня']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
    await tester.pumpWidget(const SizedBox());
  });
}

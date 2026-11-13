import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../controllers/planner_controller.dart';
import '../controllers/reminder_controller.dart';
import '../theme/palette.dart';
import '../widgets/design_icon.dart';
import '../widgets/progress_ring.dart';
import '../widgets/reminder_card.dart';
import '../widgets/task_card.dart';
import '../widgets/task_editor.dart';
import 'insights_views.dart';
import 'backup_page.dart';
import 'plans_page.dart';
import '../../domain/entities/task_validation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.planner, required this.reminder});

  final PlannerController planner;
  final ReminderController reminder;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int page = 0;
  int filter = 0;
  String? category;
  StatisticsMode statisticsMode = StatisticsMode.count;
  final draft = TextEditingController();
  final draftFocus = FocusNode();
  final scroll = ScrollController();
  String? draftError;
  Timer? timer;

  PlannerController get planner => widget.planner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => planner.refreshDate(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      planner.refreshDate();
      unawaited(widget.reminder.refresh());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    draft.dispose();
    draftFocus.dispose();
    scroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> attempt(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось сохранить изменения. Попробуйте ещё раз.',
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> add() async {
    final title = draft.text.trim();
    if (title.isEmpty || title.length > 200) {
      setState(
        () => draftError = title.isEmpty
            ? 'Напиши название задачи'
            : 'Не больше 200 символов',
      );
      return;
    }
    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      day: dayKey(planner.selected),
      category: category ?? taskCategories.first,
    );
    if (await attempt(() => planner.save(task)) && mounted) {
      if (draft.text.trim() == title && task.day == dayKey(planner.selected)) {
        draft.clear();
      }
      setState(() {
        draftError = null;
        filter = 0;
      });
      if (page == 0 && task.day == dayKey(planner.selected)) {
        draftFocus.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !draftFocus.hasFocus || draftFocus.context == null) {
            return;
          }
          unawaited(
            Scrollable.ensureVisible(
              draftFocus.context!,
              alignment: 1,
              duration: const Duration(milliseconds: 200),
            ),
          );
        });
      }
    }
  }

  Future<void> edit(Task task) async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: paper,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => TaskEditor(
        task: task,
        day: DateTime.parse(task.day),
        onSave: planner.save,
      ),
    );
    if (result != null && mounted) {
      if (result.day != task.day) selectDay(DateTime.parse(result.day));
    }
  }

  Future<void> delete(Task task) async {
    if (!await attempt(() => planner.delete(task)) || !mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Задача удалена'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () => attempt(() => planner.save(task)),
        ),
      ),
    );
  }

  Future<void> showPlans() async {
    final date = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(builder: (_) => PlansPage(planner: planner)),
    );
    if (date != null && mounted) selectDay(date);
  }

  void showBackups() {
    draftFocus.unfocus();
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => BackupPage(planner: planner)),
    );
  }

  Future<void> moveUnfinished() async {
    TaskMove? moved;
    if (!await attempt(() async {
          moved = await planner.moveUnfinishedToTomorrow();
        }) ||
        !mounted ||
        moved == null ||
        moved!.tasks.isEmpty) {
      return;
    }
    final undo = moved!;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Перенесено на завтра: ${undo.tasks.length}'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () async {
            try {
              await planner.undoMove(undo);
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Не удалось отменить перенос. Задачи могли измениться — проверьте план на завтра.',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void selectDay(DateTime day) {
    planner.select(day);
    draft.clear();
    draftFocus.unfocus();
    setState(() {
      page = 0;
      filter = 0;
      category = null;
      draftError = null;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Future<void> chooseDate() async {
    final date = await pickDay(context, planner.selected);
    if (date != null && mounted) selectDay(date);
  }

  Future<void> dayMenu() async {
    draftFocus.unfocus();
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('План на день', style: TextStyle(fontSize: 24)),
                ),
              ),
              ListTile(
                key: const ValueKey('today'),
                selected: planner.selected == planner.today,
                selectedTileColor: sand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Сегодня'),
                subtitle: Text(
                  DateFormat('d MMMM', 'ru').format(planner.today),
                ),
                trailing: planner.selected == planner.today
                    ? const DesignIcon(DesignSymbol.check, size: 20)
                    : null,
                leading: const DesignIcon(DesignSymbol.sun),
                onTap: () => Navigator.pop(context, 'today'),
              ),
              ListTile(
                key: const ValueKey('tomorrow'),
                selected: planner.selected == nextDay(planner.today),
                selectedTileColor: sand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Завтра'),
                subtitle: Text(
                  DateFormat('d MMMM', 'ru').format(nextDay(planner.today)),
                ),
                trailing: planner.selected == nextDay(planner.today)
                    ? const DesignIcon(DesignSymbol.check, size: 20)
                    : null,
                leading: const DesignIcon(DesignSymbol.moon),
                onTap: () => Navigator.pop(context, 'tomorrow'),
              ),
              ListTile(
                key: const ValueKey('choose-date'),
                title: const Text('Выбрать дату'),
                leading: const DesignIcon(DesignSymbol.calendar),
                onTap: () => Navigator.pop(context, 'date'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (value == 'today') selectDay(planner.today);
    if (value == 'tomorrow') selectDay(nextDay(planner.today));
    if (value == 'date') await chooseDate();
  }

  void setPage(int value) {
    draftFocus.unfocus();
    if (value == 0 && page != 0) planner.select(planner.today);
    setState(() => page = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: planner,
    builder: (context, _) => Scaffold(
      backgroundColor: paper,
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom == 0
          ? Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: navigation(),
              ),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: ListView(
                  controller: scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    if (page == 0)
                      ...dayView()
                    else if (page == 1)
                      ArchiveView(
                        days: planner.pastDays,
                        tasks: planner.tasks,
                        today: planner.today,
                        onToggle: (task) => attempt(
                          () => planner.save(task.copyWith(done: !task.done)),
                        ),
                        onEdit: edit,
                        onOpenDay: selectDay,
                        onChooseDate: chooseDate,
                        busy: planner.busy,
                      )
                    else if (page == 2)
                      StatisticsView(
                        statistics: planner.statistics,
                        today: planner.today,
                        mode: statisticsMode,
                        onModeChanged: (value) =>
                            setState(() => statisticsMode = value),
                      )
                    else
                      AwardsView(awards: planner.statistics.awards),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget navigation() {
    const labels = ['Сегодня', 'Архив', 'Статистика', 'Ачивки'];
    const symbols = [
      DesignSymbol.sun,
      DesignSymbol.archive,
      DesignSymbol.chart,
      DesignSymbol.trophy,
    ];
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: card.withValues(alpha: .95),
            border: Border(top: BorderSide(color: inkOpacity(.05))),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Flexible(
                      child: Semantics(
                        selected: page == i,
                        button: true,
                        child: InkWell(
                          onTap: () => setPage(i),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.sizeOf(context).width < 360
                                  ? 6
                                  : 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: page == i ? sage : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DesignIcon(
                                  symbols[i],
                                  size: 22,
                                  color: page == i ? ink : inkOpacity(.4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  labels[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: page == i ? ink : inkOpacity(.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> dayView() {
    final tasks = planner.selectedTasks;
    final done = tasks.where((t) => t.done).length;
    final percent = tasks.isEmpty ? 0 : (done / tasks.length * 100).round();
    final visible = tasks
        .where(
          (t) =>
              (category == null || t.category == category) &&
              (filter == 0 || (filter == 1 ? !t.done : t.done)),
        )
        .toList();
    final dateText = DateFormat('EEEE, d MMMM', 'ru').format(planner.selected);
    final isToday = planner.selected == planner.today;
    final yesterday = DateTime(
      planner.today.year,
      planner.today.month,
      planner.today.day - 1,
    );
    final title = isToday
        ? 'Твой день'
        : planner.selected == yesterday
        ? 'Вчера'
        : planner.selected == nextDay(planner.today)
        ? 'Завтра'
        : 'Твои планы';
    return [
      if (planner.damagedCount > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              'Не удалось прочитать записей: ${planner.damagedCount}. Исправные задачи доступны, повреждённые сохранены отдельно. Подробнее — в «Копии задач».',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      Material(
        color: sand.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const ValueKey('day-selector'),
          onTap: dayMenu,
          borderRadius: BorderRadius.circular(18),
          child: Semantics(
            button: true,
            label: 'Выбрать день',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const DesignIcon(DesignSymbol.calendar, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? 'Сегодня'
                              : planner.selected == nextDay(planner.today)
                              ? 'Завтра'
                              : 'Выбранный день',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateText[0].toUpperCase()}${dateText.substring(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: inkOpacity(.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const RotatedBox(
                    quarterTurns: 1,
                    child: DesignIcon(DesignSymbol.chevron, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: Text(title, style: pageHeading)),
          IconButton(
            tooltip: 'Будущие планы',
            onPressed: showPlans,
            icon: const Icon(Icons.event_note),
          ),
          IconButton(
            tooltip: 'Копии задач',
            onPressed: showBackups,
            icon: const Icon(Icons.folder_copy_outlined),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cream,
          border: Border.all(color: inkOpacity(.1)),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: paper.withValues(alpha: .3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ProgressRing(percent: percent),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Выполнено', style: captionStyle(.65)),
                        Text(
                          '$done из ${tasks.length}',
                          style: const TextStyle(fontSize: 30, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const DesignIcon(
                              DesignSymbol.flame,
                              size: 16,
                              filled: true,
                              stroke: 1,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Серия: ${planner.statistics.streak} дн.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ReminderCard(controller: widget.reminder),
      const SizedBox(height: 28),
      Row(
        children: [
          Expanded(
            child: PopupMenuButton<int>(
              tooltip: 'Фильтр задач',
              initialValue: filter,
              onSelected: (value) => setState(() => filter = value),
              itemBuilder: (_) => [
                for (final (index, label) in [
                  'Все',
                  'В процессе',
                  'Готово',
                ].indexed)
                  PopupMenuItem(value: index, child: Text(label)),
              ],
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    filter == 0
                        ? 'ЗАДАЧИ'
                        : filter == 1
                        ? 'В ПРОЦЕССЕ'
                        : 'ГОТОВО',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: inkOpacity(.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: 'Категория задач',
              initialValue: category ?? '',
              onSelected: (value) =>
                  setState(() => category = value.isEmpty ? null : value),
              itemBuilder: (_) => [
                const PopupMenuItem(value: '', child: Text('Все категории')),
                for (final value in {
                  ...taskCategories,
                  ...tasks.map((t) => t.category),
                })
                  PopupMenuItem(value: value, child: Text(value)),
              ],
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category ?? 'Все категории',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      if (!planner.selected.isAfter(planner.today))
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('move-unfinished'),
            onPressed: planner.busy || !tasks.any((t) => !t.done)
                ? null
                : moveUnfinished,
            icon: const Icon(Icons.forward),
            label: Text(
              'Все незавершённые на завтра (${tasks.where((t) => !t.done).length})',
            ),
          ),
        ),
      const SizedBox(height: 12),
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            tasks.isEmpty
                ? 'Пока пусто. Запланируй свой день.'
                : 'В этом фильтре пока нет задач.',
            textAlign: TextAlign.center,
            style: captionStyle(.45),
          ),
        ),
      for (var i = 0; i < visible.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        TaskCard(
          task: visible[i],
          onToggle: planner.busy
              ? null
              : () => attempt(
                  () =>
                      planner.save(visible[i].copyWith(done: !visible[i].done)),
                ),
          onEdit: planner.busy ? null : () => edit(visible[i]),
          onDelete: planner.busy ? null : () => delete(visible[i]),
        ),
      ],
      const SizedBox(height: 12),
      TextFieldTapRegion(
        key: const ValueKey('quick-entry'),
        child: CustomPaint(
          painter: _DashedBorder(focused: draftFocus.hasFocus),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('quick-task'),
                    controller: draft,
                    readOnly: planner.busy,
                    focusNode: draftFocus,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    onEditingComplete: () {},
                    onSubmitted: (_) => planner.busy ? null : add(),
                    onTap: () => setState(() {}),
                    onTapOutside: (_) {
                      draftFocus.unfocus();
                      setState(() {});
                    },
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Новая задача…',
                      counterText: '',
                      hintStyle: TextStyle(color: inkOpacity(.45)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Добавить',
                  child: Semantics(
                    button: true,
                    label: 'Добавить задачу',
                    child: InkWell(
                      key: const ValueKey('quick-add'),
                      onTap: planner.busy ? null : add,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const DesignIcon(
                          DesignSymbol.plus,
                          color: cream,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (draftError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            draftError!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DesignIcon(DesignSymbol.moon, size: 16, color: inkOpacity(.45)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isToday
                  ? 'После полуночи карточка уйдёт в архив'
                  : 'План на ${DateFormat('d MMMM', 'ru').format(planner.selected)}',
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: inkOpacity(.45),
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.focused});

  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(16),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = focused ? cream : inkOpacity(.2);
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 10) {
        canvas.drawPath(metric.extractPath(start, start + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.focused != focused;
}

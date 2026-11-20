import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../controllers/planner_controller.dart';
import '../controllers/reminder_controller.dart';
import '../theme/palette.dart';
import '../widgets/design_icon.dart';
import '../controllers/theme_controller.dart';
import 'settings_page.dart';
import '../widgets/animated_task_list.dart';
import '../widgets/task_editor.dart';
import 'insights_views.dart';
import 'backup_page.dart';
import 'plans_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.planner,
    required this.reminder,
    required this.appearance,
  });

  final PlannerController planner;
  final ReminderController reminder;
  final ThemeController appearance;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int page = 0;
  int filter = 0;
  StatisticsMode statisticsMode = StatisticsMode.count;
  final draft = TextEditingController();
  final draftFocus = FocusNode();
  final scroll = ScrollController();
  final pages = PageController();
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
    pages.dispose();
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

  Future<void> edit(Task task, {bool selectEditedDay = true}) async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppPalette.of(context).paper,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => TaskEditor(
        task: task,
        day: DateTime.parse(task.day),
        onSave: planner.save,
      ),
    );
    if (result != null && mounted) {
      if (selectEditedDay && result.day != task.day) {
        selectDay(DateTime.parse(result.day));
      }
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

  Future<void> copyUnfinished() async {
    TaskCopy? moved;
    if (!await attempt(() async {
          moved = await planner.copyUnfinishedToTomorrow();
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
        content: Text('Скопировано на завтра: ${undo.tasks.length}'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () async {
            try {
              await planner.undoCopy(undo);
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Не удалось отменить копирование. Задачи могли измениться — проверьте план на завтра.',
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
      draftError = null;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
    animatePage(0);
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
      backgroundColor: AppPalette.of(context).paper,
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
                selectedTileColor: AppPalette.of(context).sand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppPalette.of(context).radius,
                  ),
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
                selectedTileColor: AppPalette.of(context).sand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppPalette.of(context).radius,
                  ),
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

  void animatePage(int value) {
    if (!pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      pages.jumpToPage(value);
    } else {
      pages.animateToPage(
        value,
        duration: const Duration(milliseconds: 315),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void setPage(int value) {
    draftFocus.unfocus();
    if (value == 0 && page != 0) planner.select(planner.today);
    animatePage(value);
  }

  Future<void> showDayDetails(DateTime day) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppPalette.of(context).paper,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: .65,
      child: ListenableBuilder(
        listenable: planner,
        builder: (context, _) {
          final tasks = planner.tasks
              .where((t) => t.day == dayKey(day))
              .toList();
          final done = tasks.where((t) => t.done).length;
          return ListView(
            key: ValueKey('day-details-${dayKey(day)}'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                DateFormat('d MMMM yyyy', 'ru').format(day),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Выполнено $done из ${tasks.length}',
                style: captionStyle(context),
              ),
              const SizedBox(height: 16),
              if (tasks.isEmpty) const Text('На этот день задач нет.'),
              AnimatedTaskList(
                tasks: tasks,
                busy: planner.busy,
                onToggle: (task) => attempt(
                  () => planner.save(task.copyWith(done: !task.done)),
                ),
                onEdit: (task) => edit(task, selectEditedDay: false),
                onDelete: delete,
              ),
              TextButton.icon(
                key: const ValueKey('day-details-add'),
                onPressed: planner.busy
                    ? null
                    : () => showModalBottomSheet<Task>(
                        context: sheetContext,
                        isScrollControlled: true,
                        useSafeArea: true,
                        showDragHandle: true,
                        backgroundColor: AppPalette.of(context).paper,
                        builder: (_) =>
                            TaskEditor(day: day, onSave: planner.save),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Добавить задачу'),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget tabContent(int index) => ListView(
    key: PageStorageKey('tab-scroll-$index'),
    controller: index == 0 ? scroll : null,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
    children: [
      if (index == 0)
        ...dayView()
      else if (index == 1)
        ArchiveView(
          days: planner.pastDays,
          tasks: planner.tasks,
          today: planner.today,
          onToggle: (task) =>
              attempt(() => planner.save(task.copyWith(done: !task.done))),
          onEdit: edit,
          onDelete: delete,
          onOpenDay: selectDay,
          onChooseDate: chooseDate,
          busy: planner.busy,
          onBackups: showBackups,
        )
      else if (index == 2)
        StatisticsView(
          statistics: planner.statistics,
          today: planner.today,
          mode: statisticsMode,
          onOpenDay: showDayDetails,
          onSettings: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SettingsPage(
                appearance: widget.appearance,
                reminder: widget.reminder,
              ),
            ),
          ),
          onModeChanged: (value) => setState(() => statisticsMode = value),
        )
      else
        AwardsView(awards: planner.statistics.awards),
    ],
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: planner,
    builder: (context, _) => Scaffold(
      backgroundColor: AppPalette.of(context).paper,
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
          child: SafeArea(
            bottom: false,
            child: PageView.builder(
              key: const ValueKey('tab-pages'),
              controller: pages,
              pageSnapping: false,
              physics: const _TabScrollPhysics(),
              itemCount: 4,
              onPageChanged: (value) {
                draftFocus.unfocus();
                setState(() => page = value);
              },
              itemBuilder: (context, index) => tabContent(index),
            ),
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
            color: AppPalette.of(context).card.withValues(alpha: .95),
            border: Border(
              top: BorderSide(color: AppPalette.of(context).inkOpacity(.05)),
            ),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: AnimatedBuilder(
                animation: pages,
                builder: (context, _) {
                  final position =
                      pages.hasClients && pages.position.hasContentDimensions
                      ? (pages.page ?? page.toDouble()).clamp(0.0, 3.0)
                      : page.toDouble();
                  final colors = AppPalette.of(context);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              -1 + 2 * position / (labels.length - 1),
                              0,
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 1 / labels.length,
                              heightFactor: 1,
                              child: DecoratedBox(
                                key: const ValueKey('nav-indicator'),
                                decoration: BoxDecoration(
                                  color: colors.sage,
                                  borderRadius: BorderRadius.circular(
                                    colors.navRadius,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < labels.length; i++)
                              Expanded(
                                child: Semantics(
                                  selected: page == i,
                                  button: true,
                                  child: InkWell(
                                    onTap: () => setPage(i),
                                    borderRadius: BorderRadius.circular(
                                      colors.navRadius,
                                    ),
                                    child: Container(
                                      key: ValueKey('nav-section-$i'),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Transform.translate(
                                            offset: Offset(
                                              0,
                                              -2 *
                                                  (1 - (position - i).abs())
                                                      .clamp(0.0, 1.0),
                                            ),
                                            child: DesignIcon(
                                              symbols[i],
                                              size: 22,
                                              color: Color.lerp(
                                                colors.inkOpacity(.4),
                                                colors.ink,
                                                (1 - (position - i).abs())
                                                    .clamp(0.0, 1.0),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            labels[i],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              height: 1.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color.lerp(
                                                colors.inkOpacity(.4),
                                                colors.ink,
                                                (1 - (position - i).abs())
                                                    .clamp(0.0, 1.0),
                                              ),
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
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> dayView() {
    final colors = AppPalette.of(context);
    final tasks = planner.selectedTasks;
    final done = tasks.where((t) => t.done).length;
    final percent = tasks.isEmpty ? 0 : (done / tasks.length * 100).round();
    final visible = tasks
        .where((t) => (filter == 0 || (filter == 1 ? !t.done : t.done)))
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
        color: AppPalette.of(context).sand.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
        child: InkWell(
          key: const ValueKey('day-selector'),
          onTap: dayMenu,
          borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
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
                            color: AppPalette.of(context).inkOpacity(.55),
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
          Expanded(child: Text(title, style: pageHeading(context))),
          IconButton(
            tooltip: 'Будущие планы',
            onPressed: showPlans,
            icon: const Icon(Icons.event_note),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        key: const ValueKey('day-progress'),
        padding: EdgeInsets.symmetric(
          horizontal: colors.design == AppDesign.editorial ? 0 : 16,
          vertical: 12,
        ),
        decoration: colors.panel(
          color: colors.hero,
          flat: colors.design == AppDesign.editorial,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Выполнено $done из ${tasks.length}',
                    style: TextStyle(fontSize: 14, color: colors.onHero),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: colors.heading.copyWith(
                    fontSize: 18,
                    color: colors.design == AppDesign.strict
                        ? colors.accent
                        : colors.strong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(colors.lined ? 1 : 8),
              child: LinearProgressIndicator(
                value: tasks.isEmpty ? 0 : done / tasks.length,
                minHeight: colors.playful ? 7 : 4,
                color: colors.heroAccent,
                backgroundColor: colors.onHero.withValues(alpha: .12),
                semanticsLabel: 'Выполнено $percent процентов',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
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
                      color: AppPalette.of(context).inkOpacity(.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
            style: captionStyle(context, .45),
          ),
        ),
      AnimatedTaskList(
        key: ValueKey('day-tasks-${dayKey(planner.selected)}-$filter'),
        tasks: visible,
        busy: planner.busy,
        onToggle: (task) =>
            attempt(() => planner.save(task.copyWith(done: !task.done))),
        onEdit: edit,
        onDelete: delete,
      ),
      const SizedBox(height: 12),
      TextFieldTapRegion(
        key: const ValueKey('quick-entry'),
        child: CustomPaint(
          painter: _DashedBorder(
            focused: draftFocus.hasFocus,
            color: draftFocus.hasFocus
                ? AppPalette.of(context).cream
                : AppPalette.of(context).inkOpacity(.2),
          ),
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
                      hintStyle: TextStyle(
                        color: AppPalette.of(context).inkOpacity(.45),
                      ),
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
                          color: AppPalette.of(context).action,
                          borderRadius: BorderRadius.circular(
                            AppPalette.of(context).radius,
                          ),
                        ),
                        child: DesignIcon(
                          DesignSymbol.plus,
                          color: AppPalette.of(context).onAction,
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
      const SizedBox(height: 12),
      if (!planner.selected.isAfter(planner.today))
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('move-unfinished'),
            onPressed: planner.busy || !tasks.any((t) => !t.done)
                ? null
                : copyUnfinished,
            icon: const Icon(Icons.forward),
            label: Text(
              'Скопировать незавершённые на завтра (${tasks.where((t) => !t.done).length})',
            ),
          ),
        ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DesignIcon(
            DesignSymbol.moon,
            size: 16,
            color: AppPalette.of(context).inkOpacity(.45),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isToday
                  ? 'После полуночи карточка уйдёт в архив'
                  : 'План на ${DateFormat('d MMMM', 'ru').format(planner.selected)}',
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: AppPalette.of(context).inkOpacity(.45),
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.focused, required this.color});

  final Color color;

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
      ..color = color;
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 10) {
        canvas.drawPath(metric.extractPath(start, start + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.focused != focused || old.color != color;
}

// Full-width tabs retain native gesture arbitration and boundary handling.
// A deliberate slow drag needs 35% of a page; lighter flicks also advance.
class _TabScrollPhysics extends PageScrollPhysics {
  const _TabScrollPhysics({super.parent});

  @override
  _TabScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _TabScrollPhysics(parent: buildParent(ancestor));

  @override
  double get minFlingVelocity => super.minFlingVelocity * .8;

  @override
  double get minFlingDistance => super.minFlingDistance * .8;

  @override
  SpringDescription get spring {
    final original = super.spring;
    // Stretch the settling time by 5%, retaining the native damping ratio.
    return SpringDescription(
      mass: original.mass,
      stiffness: original.stiffness / (1.05 * 1.05),
      damping: original.damping / 1.05,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange || position.viewportDimension <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }
    final direction = position is ScrollPosition
        ? position.userScrollDirection
        : ScrollDirection.idle;
    if (direction == ScrollDirection.idle) {
      return super.createBallisticSimulation(position, velocity);
    }
    final current = position.pixels / position.viewportDimension;
    final tolerance = toleranceFor(position);
    double target;
    if (velocity.abs() > tolerance.velocity) {
      target = velocity > 0 ? current.ceilToDouble() : current.floorToDouble();
    } else if (direction == ScrollDirection.reverse) {
      target = current - current.floor() >= .35
          ? current.ceilToDouble()
          : current.floorToDouble();
    } else {
      target = current.ceil() - current >= .35
          ? current.floorToDouble()
          : current.ceilToDouble();
    }
    final pixels = (target * position.viewportDimension).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((pixels - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      pixels,
      velocity,
      tolerance: tolerance,
    );
  }
}

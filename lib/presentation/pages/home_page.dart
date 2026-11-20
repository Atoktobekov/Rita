import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../controllers/planner_controller.dart';
import '../controllers/reminder_controller.dart';
import '../theme/palette.dart';
import '../widgets/design_icon.dart';
import '../widgets/reference_widgets.dart';
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
  bool quickOpen = false;
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
    final result = await showDesignSheet<Task>(
      context,
      enableDrag: false,
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
    final date = await showDesignSheet<DateTime>(
      context,
      builder: (_) => PlansPage(planner: planner),
    );
    if (date != null && mounted) selectDay(date);
  }

  void showBackups() {
    draftFocus.unfocus();
    showDesignSheet<void>(
      context,
      enableDrag: false,
      builder: (_) => BackupPage(planner: planner),
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
      quickOpen = false;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
    animatePage(0);
  }

  Future<void> chooseDate() async {
    final date = await showDesignSheet<DateTime>(
      context,
      builder: (_) => CalendarSheet(initialDate: planner.selected),
    );
    if (date != null && mounted) selectDay(date);
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

  Future<void> addForDate(DateTime date) async {
    await showDesignSheet<Task>(
      context,
      enableDrag: false,
      builder: (_) => TaskEditor(day: date, onSave: planner.save),
    );
  }

  Future<void> showDayDetails(DateTime day) async {
    await showDesignSheet<void>(
      context,
      builder: (_) => ListenableBuilder(
        listenable: planner,
        builder: (context, _) {
          final c = AppPalette.of(context);
          final tasks = planner.tasks
              .where((task) => task.day == dayKey(day))
              .toList();
          final done = tasks.where((t) => t.done).length;
          return DesignSheet(
            key: ValueKey('day-details-${dayKey(day)}'),
            title: DateFormat('d MMMM, EEEE', 'ru').format(day),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    Text(
                      'Выполнено $done из ${tasks.length}',
                      style: designText(10, color: c.muted),
                    ),
                    Text(
                      'Ваш день в деталях',
                      style: designText(10, color: c.muted),
                    ),
                  ],
                ),
              ),
              if (tasks.isEmpty)
                Text(
                  'На этот день задач нет.',
                  style: designText(13, color: c.muted),
                ),
              AnimatedTaskList(
                tasks: tasks,
                busy: planner.busy,
                onToggle: (task) => attempt(
                  () => planner.save(task.copyWith(done: !task.done)),
                ),
                onEdit: (task) => edit(task, selectEditedDay: false),
                onDelete: delete,
              ),
              const SizedBox(height: 10),
              DesignButton(
                key: const ValueKey('day-details-add'),
                label: 'Добавить задачу',
                icon: DesignSymbol.plus,
                onPressed: planner.busy ? null : () => addForDate(day),
              ),
              const SizedBox(height: 17),
              Text(
                'Удерживайте задачу, чтобы изменить или удалить.',
                textAlign: TextAlign.center,
                style: designText(12, height: 1.8, color: c.muted),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget tabContent(int index) => ListView(
    key: PageStorageKey('tab-scroll-$index'),
    controller: index == 0 ? scroll : null,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(23, 0, 23, 20),
    children: [
      wordmark(AppPalette.of(context), day: index == 0),
      if (index == 0)
        ...dayView()
      else if (index == 1)
        ArchiveView(
          days: planner.pastDays,
          tasks: planner.tasks,
          onToggle: (task) =>
              attempt(() => planner.save(task.copyWith(done: !task.done))),
          onEdit: edit,
          onDelete: delete,
          onAdd: addForDate,
          onChooseDate: chooseDate,
          busy: planner.busy,
          onBackups: showBackups,
        )
      else if (index == 2)
        StatisticsView(
          statistics: planner.statistics,
          mode: statisticsMode,
          onOpenDay: showDayDetails,
          onModeChanged: (value) => setState(() => statisticsMode = value),
        )
      else
        AwardsView(
          awards: planner.statistics.awards,
          onSettings: () => showDesignSheet<void>(
            context,
            builder: (_) => SettingsPage(
              appearance: widget.appearance,
              reminder: widget.reminder,
            ),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: planner,
    builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppPalette.of(context).dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
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
              minimum: const EdgeInsets.only(top: 46),
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
    ),
  );

  Widget wordmark(AppPalette c, {required bool day}) => Container(
    height: 16 + MediaQuery.textScalerOf(context).scale(28),
    margin: EdgeInsets.only(
      bottom: day
          ? c.editorial
                ? 18
                : 8
          : 0,
    ),
    padding: EdgeInsets.only(bottom: c.editorial ? 9 : 0),
    decoration: c.editorial
        ? BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          )
        : null,
    child: Row(
      children: [
        Flexible(
          flex: 3,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(0, c.editorial ? -1 : 0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Rita',
                  style:
                      designText(
                        c.strict
                            ? 23
                            : c.editorial
                            ? 29
                            : 28,
                        color: c.playful ? c.strong : c.ink,
                        weight: c.editorial ? 500 : 700,
                        height: 1.2,
                        spacing: c.strict
                            ? -1
                            : c.editorial
                            ? -1.8
                            : -1.5,
                        font: c.editorial ? 'Literata' : 'DM Sans',
                      ).copyWith(
                        fontStyle: c.editorial
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            'Routine Assistant',
            textAlign: TextAlign.right,
            style: designText(
              c.strict ? 8 : 11,
              spacing: c.strict ? 1 : 0,
              color: c.muted,
            ),
          ),
        ),
        if (!c.editorial) ...[
          const SizedBox(width: 7),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
          ),
        ],
      ],
    ),
  );

  Widget navigation() {
    const labels = ['Сегодня', 'Архив', 'Статистика', 'Ачивки'];
    const symbols = [
      DesignSymbol.sun,
      DesignSymbol.archive,
      DesignSymbol.chart,
      DesignSymbol.award,
    ];
    final c = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 34),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 5),
          child: AnimatedBuilder(
            animation: pages,
            builder: (context, _) {
              final position =
                  pages.hasClients && pages.position.hasContentDimensions
                  ? (pages.page ?? page.toDouble()).clamp(0.0, 3.0)
                  : page.toDouble();
              return Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment(-1 + 2 * position / 3, 0),
                        child: FractionallySizedBox(
                          widthFactor: .25,
                          heightFactor: 1,
                          child: DecoratedBox(
                            key: const ValueKey('nav-indicator'),
                            decoration: BoxDecoration(
                              color: c.navHighlight,
                              borderRadius: BorderRadius.circular(c.navRadius),
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
                                key: ValueKey('nav-section-$i'),
                                borderRadius: BorderRadius.circular(
                                  c.navRadius,
                                ),
                                onTap: () => setPage(i),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 61,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DesignIcon(
                                        symbols[i],
                                        size: 23,
                                        color: navColor(c, position, i),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        labels[i],
                                        textAlign: TextAlign.center,
                                        style: designText(
                                          10,
                                          color: navColor(c, position, i),
                                          weight: page == i
                                              ? 550
                                              : c.strict
                                              ? 500
                                              : 400,
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
    );
  }

  Color navColor(AppPalette c, num position, int tab) => Color.lerp(
    c.muted,
    c.playful
        ? c.strong
        : c.strict && c.dark
        ? c.paper
        : c.ink,
    (1 - (position - tab).abs()).clamp(0.0, 1.0).toDouble(),
  )!;

  List<Widget> dayView() {
    final c = AppPalette.of(context);
    final tasks = planner.selectedTasks;
    final done = tasks.where((t) => t.done).length;
    final percent = tasks.isEmpty ? 0 : (done / tasks.length * 100).round();
    final visible = tasks
        .where((t) => filter == 0 || (filter == 1 ? !t.done : t.done))
        .toList();
    final today = planner.today;
    final tomorrow = nextDay(today);
    final isToday = planner.selected == today;
    final otherDate = !isToday && planner.selected != tomorrow;
    final headline = switch (c.design) {
      AppDesign.strict => 'План на день',
      AppDesign.play => 'Твой день.',
      _ => 'Хороший день',
    };
    final subhead = switch (c.design) {
      AppDesign.play => 'Не всё сразу. По одной победе.',
      AppDesign.editorial => 'Оставьте место для важного.',
      _ => 'Маленькие шаги к большому.',
    };
    final progress = Container(
      key: const ValueKey('day-progress'),
      padding: c.editorial
          ? const EdgeInsets.only(bottom: 19)
          : EdgeInsets.fromLTRB(
              c.strict ? 17 : 16,
              c.strict ? 17 : 12,
              c.strict ? 17 : 16,
              c.strict
                  ? 17
                  : c.playful
                  ? 13
                  : 12,
            ),
      decoration: c.editorial
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            )
          : BoxDecoration(
              color: c.strict
                  ? c.hero
                  : c.playful && !c.dark
                  ? const Color(0xFFECE5FA)
                  : c.cream,
              borderRadius: BorderRadius.circular(c.radius),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Выполнено '),
                      TextSpan(
                        text: '$done из ${tasks.length}',
                        style: designText(c.editorial ? 11 : 12, weight: 550),
                      ),
                    ],
                  ),
                  style: designText(c.editorial ? 11 : 12, color: c.onHero),
                ),
              ),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$percent'),
                    TextSpan(text: '%', style: designText(12)),
                  ],
                ),
                style: designText(
                  c.editorial ? 21 : 20,
                  color: c.strict ? c.accent : c.ink,
                  font: c.editorial ? 'Literata' : 'DM Sans',
                  weight: 500,
                ),
              ),
            ],
          ),
          SizedBox(height: c.playful ? 10 : 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: percent / 100),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: c.playful
                    ? 7
                    : c.editorial
                    ? 3
                    : 4,
                borderRadius: BorderRadius.circular(8),
                color: c.strict
                    ? c.accent
                    : c.playful
                    ? const Color(0xFFA58BDC)
                    : c.editorial
                    ? const Color(0xFF8BAAB5)
                    : const Color(0xFFDFAD70),
                backgroundColor: c.strict
                    ? const Color(0x22FFFFFF)
                    : c.playful && !c.dark
                    ? const Color(0xFFDCD1EE)
                    : c.inkOpacity(.07),
                semanticsLabel: 'Выполнено $percent процентов',
              ),
            ),
          ),
          if (c.playful) ...[
            const SizedBox(height: 8),
            Text(
              'Хорошее начало. Продолжим?',
              style: designText(9, color: c.muted),
            ),
          ],
        ],
      ),
    );

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
      Container(
        key: const ValueKey('day-selector'),
        padding: EdgeInsets.all(c.strict ? 0 : 3),
        decoration: BoxDecoration(
          color: c.editorial ? null : c.sand,
          borderRadius: BorderRadius.circular(c.lined ? 4 : 14),
          border: c.lined ? Border.all(color: c.line) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: dateTab(
                label: 'Сегодня',
                key: const ValueKey('today'),
                selected: isToday,
                onTap: () => selectDay(today),
              ),
            ),
            if (!c.strict) const SizedBox(width: 4),
            Expanded(
              child: dateTab(
                label: 'Завтра',
                key: const ValueKey('tomorrow'),
                selected: planner.selected == tomorrow,
                onTap: () => selectDay(tomorrow),
              ),
            ),
            if (!c.strict) const SizedBox(width: 4),
            SizedBox(
              width: 53,
              child: dateTab(
                key: const ValueKey('choose-date'),
                selected: otherDate,
                onTap: chooseDate,
              ),
            ),
          ],
        ),
      ),
      DesignHeader(
        eyebrow: DateFormat(
          'EEEE, d MMMM',
          'ru',
        ).format(planner.selected).toUpperCase(),
        title: isToday ? headline : 'Новый день',
        subtitle: subhead,
        day: true,
        mark: c.design == AppDesign.warm
            ? const DesignIcon(
                DesignSymbol.sun,
                size: 29,
                color: Color(0xFFD7A76C),
              )
            : null,
      ),
      if (c.playful)
        Transform.rotate(angle: -.0174533, child: progress)
      else
        progress,
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 11),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  switch (filter) {
                    1 => 'В ПРОЦЕССЕ',
                    2 => 'ГОТОВО',
                    _ => c.strict ? 'ЗАДАЧИ' : 'Мои задачи',
                  },
                  style: designText(
                    c.strict
                        ? 10
                        : c.editorial
                        ? 14
                        : 13,
                    weight: c.editorial ? 400 : 550,
                    spacing: c.strict ? 1 : 0,
                    font: c.editorial ? 'Literata' : 'Golos Text',
                  ),
                ),
              ),
              Text(
                visible.length.toString().padLeft(2, '0'),
                style: designText(10, color: c.muted, font: 'DM Sans'),
              ),
            ],
          ),
        ),
      ),
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 30, 0, 36),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: c.cream,
                  borderRadius: BorderRadius.circular(45),
                ),
                alignment: Alignment.center,
                child: const DesignIcon(
                  DesignSymbol.sun,
                  size: 56,
                  color: Color(0xFFC6A06F),
                ),
              ),
              const SizedBox(height: 21),
              Text(
                tasks.isEmpty
                    ? 'День — чистый лист'
                    : 'В этом фильтре пока нет задач.',
                textAlign: TextAlign.center,
                style: designText(18, weight: 500),
              ),
              if (tasks.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Никакой спешки. Добавьте то,\nчто действительно важно.',
                  textAlign: TextAlign.center,
                  style: designText(12, height: 1.8, color: c.muted),
                ),
              ],
            ],
          ),
        )
      else
        AnimatedTaskList(
          key: ValueKey('day-tasks-${dayKey(planner.selected)}-$filter'),
          tasks: visible,
          busy: planner.busy,
          onToggle: (task) =>
              attempt(() => planner.save(task.copyWith(done: !task.done))),
          onEdit: edit,
          onDelete: delete,
        ),
      SizedBox(
        height: quickOpen
            ? 12
            : c.strict
            ? 20
            : c.editorial
            ? 19
            : 10,
      ),
      if (!quickOpen)
        DesignButton(
          key: const ValueKey('quick-open'),
          label: 'Добавить задачу',
          icon: DesignSymbol.plus,
          onPressed: planner.busy
              ? null
              : () {
                  setState(() => quickOpen = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && quickOpen) draftFocus.requestFocus();
                  });
                },
        )
      else
        TextFieldTapRegion(
          key: const ValueKey('quick-entry'),
          child: Container(
            decoration: BoxDecoration(
              color: c.cream,
              border: Border.all(color: c.accent),
              borderRadius: BorderRadius.circular(c.radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      textInputAction: TextInputAction.done,
                      style: designText(13),
                      decoration: const InputDecoration(
                        hintText: 'Что нужно сделать?',
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  Material(
                    color: c.accent,
                    child: InkWell(
                      key: const ValueKey('quick-add'),
                      onTap: planner.busy ? null : add,
                      child: Semantics(
                        button: true,
                        label: 'Добавить задачу',
                        child: SizedBox(
                          width: 48,
                          height: 49,
                          child: Center(
                            child: DesignIcon(
                              DesignSymbol.arrow,
                              color: c.dark ? c.paper : c.ink,
                            ),
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
            style: designText(12, color: Theme.of(context).colorScheme.error),
          ),
        ),
      SizedBox(height: c.playful ? 14 : 16),
      InkWell(
        key: const ValueKey('move-unfinished'),
        onTap: planner.busy || planner.selected.isAfter(today)
            ? null
            : () {
                if (done == tasks.length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Нет незавершённых задач')),
                  );
                } else {
                  copyUnfinished();
                }
              },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DesignIcon(DesignSymbol.copy, size: 17, color: c.muted),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Скопировать незавершённые на завтра',
                  textAlign: TextAlign.center,
                  style: designText(11, color: c.muted),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 5),
      InkWell(
        onTap: showPlans,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Expanded(child: Text('Будущие планы', style: designText(13))),
              const DesignIcon(DesignSymbol.arrow, size: 18),
            ],
          ),
        ),
      ),
    ];
  }

  Widget dateTab({
    required Key key,
    String? label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final c = AppPalette.of(context);
    final ink = selected ? (c.lined ? c.paper : c.onSelectedSegment) : c.muted;
    final radius = BorderRadius.circular(
      c.strict
          ? 3
          : c.editorial
          ? 2
          : label == null
          ? 0
          : 10,
    );
    return Semantics(
      selected: selected,
      button: true,
      label: label == null ? 'Выбрать дату в календаре' : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? (c.lined && !c.dark ? c.ink : c.selectedSegment)
              : null,
          borderRadius: radius,
          boxShadow: selected && !c.lined
              ? const [
                  BoxShadow(
                    color: Color(0x05000000),
                    offset: Offset(0, 2),
                    blurRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: key,
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              decoration: label == null
                  ? BoxDecoration(
                      border: Border(left: BorderSide(color: c.line)),
                    )
                  : null,
              child: label == null
                  ? DesignIcon(DesignSymbol.calendar, size: 21, color: ink)
                  : Text(
                      label,
                      style: designText(
                        13,
                        color: ink,
                        weight: selected ? 550 : 400,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/task_statistics.dart';
import '../theme/palette.dart';
import '../widgets/design_icon.dart';
import '../widgets/progress_ring.dart';
import '../widgets/animated_task_list.dart';

TextStyle pageHeading(BuildContext context) => AppPalette.of(context).heading;

TextStyle captionStyle(BuildContext context, [double opacity = .55]) =>
    TextStyle(
      fontSize: 14,
      height: 20 / 14,
      color: AppPalette.of(context).muted,
    );

BoxDecoration softCard(BuildContext context, {Color? color}) =>
    AppPalette.of(context).panel(color: color);

class ArchiveView extends StatefulWidget {
  const ArchiveView({
    super.key,
    required this.days,
    required this.tasks,
    required this.today,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenDay,
    required this.onChooseDate,
    this.busy = false,
    this.onBackups,
  });

  final bool busy;
  final VoidCallback? onBackups;
  final List<String> days;
  final List<Task> tasks;
  final DateTime today;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final ValueChanged<DateTime> onOpenDay;
  final VoidCallback onChooseDate;

  @override
  State<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends State<ArchiveView> {
  String? open;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text('Архив', style: pageHeading(context))),
          IconButton(
            tooltip: 'Копии задач',
            onPressed: widget.onBackups,
            icon: const Icon(Icons.folder_copy_outlined),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text('Прошедшие дни можно редактировать', style: captionStyle(context)),
      const SizedBox(height: 20),
      if (widget.days.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'Здесь появится история твоих дней.',
            style: captionStyle(context, .45),
          ),
        ),
      for (final day in widget.days) ...[
        Builder(
          builder: (context) {
            final tasks = widget.tasks.where((t) => t.day == day).toList();
            final done = tasks.where((t) => t.done).length;
            final percent = tasks.isEmpty
                ? 0
                : (done / tasks.length * 100).round();
            final date = DateTime.parse(day);
            final yesterday = DateTime(
              widget.today.year,
              widget.today.month,
              widget.today.day - 1,
            );
            return Container(
              decoration: AppPalette.of(
                context,
              ).panel(flat: AppPalette.of(context).lined),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  InkWell(
                    key: ValueKey('archive-$day'),
                    onTap: () =>
                        setState(() => open = open == day ? null : day),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                AppPalette.of(context).cream,
                                AppPalette.of(context).ink,
                                (percent * .85).round() / 100,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppPalette.of(context).radius,
                              ),
                            ),
                            child: Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 18,
                                height: 1.55,
                                color: percent > 45
                                    ? AppPalette.of(context).cream
                                    : AppPalette.of(context).ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  date == yesterday
                                      ? 'Вчера'
                                      : DateFormat(
                                          date.year == widget.today.year
                                              ? 'd MMMM'
                                              : 'd MMMM yyyy',
                                          'ru',
                                        ).format(date),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$done из ${tasks.length} задач',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    color: AppPalette.of(
                                      context,
                                    ).inkOpacity(.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: open == day ? .25 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: DesignIcon(
                              DesignSymbol.chevron,
                              size: 20,
                              color: AppPalette.of(context).inkOpacity(.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (open == day)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          AnimatedTaskList(
                            key: ValueKey('archive-tasks-$day'),
                            tasks: tasks,
                            busy: widget.busy,
                            onToggle: widget.onToggle,
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => widget.onOpenDay(date),
                              child: const Text('Открыть день'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
      if (widget.days.isEmpty)
        TextButton(
          onPressed: widget.onChooseDate,
          child: const Text('Открыть дату'),
        ),
    ],
  );
}

enum StatisticsMode { count, percent }

class StatisticsView extends StatelessWidget {
  const StatisticsView({
    super.key,
    required this.statistics,
    required this.today,
    required this.mode,
    required this.onModeChanged,
    required this.onOpenDay,
    this.onSettings,
  });

  final VoidCallback? onSettings;
  final TaskStatistics statistics;
  final DateTime today;
  final StatisticsMode mode;
  final ValueChanged<StatisticsMode> onModeChanged;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final stats = statistics;
    final showCount = mode == StatisticsMode.count;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final days = stats.week.skip(1).toList();
    final maximum = days.fold(
      1,
      (value, day) => day.completed > value ? day.completed : value,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Статистика',
                style: pageHeading(context).copyWith(fontSize: 28),
              ),
            ),
            IconButton(
              tooltip: 'Настройки',
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
            PopupMenuButton<StatisticsMode>(
              tooltip: 'Настройки статистики',
              position: PopupMenuPosition.under,
              offset: const Offset(0, 4),
              onSelected: onModeChanged,
              color: AppPalette.of(context).card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppPalette.of(context).radius,
                ),
              ),
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPalette.of(context).card,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppPalette.of(context).inkOpacity(.1),
                  ),
                ),
                child: const Center(child: Icon(Icons.bar_chart, size: 20)),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem<StatisticsMode>(
                  enabled: false,
                  child: Text(
                    'ПОКАЗЫВАТЬ',
                    style: TextStyle(fontSize: 11, letterSpacing: 1.1),
                  ),
                ),
                for (final (value, label) in [
                  (StatisticsMode.count, 'Число задач'),
                  (StatisticsMode.percent, 'Проценты'),
                ])
                  PopupMenuItem(
                    value: value,
                    child: Semantics(
                      selected: mode == value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: mode == value
                              ? AppPalette.of(context).sand
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(label)),
                            if (mode == value)
                              const DesignIcon(
                                DesignSymbol.check,
                                size: 16,
                                stroke: 2.6,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(compact ? 16 : 24),
          decoration: colors.panel(color: colors.hero),
          child: Row(
            children: [
              ProgressRing(
                percent: stats.percent,
                size: 116,
                stroke: 12,
                fontSize: 30,
                color: colors.heroAccent,
                textColor: colors.onHero,
                child: showCount
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${stats.completed}',
                            style: colors.heading.copyWith(
                              fontSize: 30,
                              height: 1,
                              color: colors.onHero,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'из ${stats.total}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onHero.withValues(alpha: .8),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
              SizedBox(width: compact ? 16 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showCount ? 'Выполнено задач' : 'Процент выполнения',
                      style: captionStyle(
                        context,
                        .65,
                      ).copyWith(color: colors.onHero.withValues(alpha: .85)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.percent >= 70
                          ? 'Отличный темп!'
                          : 'Есть куда расти',
                      style: colors.heading.copyWith(
                        fontSize: 20,
                        height: 1.375,
                        color: colors.onHero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: colors.panel(
                    flat: colors.design == AppDesign.editorial,
                    color: colors.playful
                        ? (i == 0 ? colors.positive : colors.celebration)
                        : colors.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i == 0 ? 'Всего задач' : 'Выполнено',
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.of(context).muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        i == 0
                            ? '${stats.total}'
                            : showCount
                            ? '${stats.completed}'
                            : '${stats.percent}%',
                        style: colors.heading.copyWith(
                          fontSize: 36,
                          height: 1.11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: colors.panel(flat: colors.design == AppDesign.editorial),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Последние 6 дней',
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 114 + MediaQuery.textScalerOf(context).scale(10) * 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, day) in days.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          key: ValueKey('chart-day-${dayKey(day.day)}'),
                          onTap: () => onOpenDay(day.day),
                          borderRadius: BorderRadius.circular(12),
                          child: Semantics(
                            button: true,
                            label:
                                '${DateFormat('d MMMM', 'ru').format(day.day)}: ${day.completed} из ${day.total}',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  showCount
                                      ? '${day.completed}'
                                      : '${(day.ratio * 100).round()}%',
                                  key: ValueKey(
                                    'chart-value-${dayKey(day.day)}',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.of(
                                      context,
                                    ).inkOpacity(.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedContainer(
                                  key: ValueKey('chart-bar-${dayKey(day.day)}'),
                                  duration: const Duration(milliseconds: 500),
                                  height:
                                      98 *
                                      (showCount
                                              ? day.completed / maximum
                                              : day.ratio)
                                          .clamp(.04, 1.0),
                                  decoration: BoxDecoration(
                                    color: dayKey(day.day) == dayKey(today)
                                        ? AppPalette.of(context).ink
                                        : AppPalette.of(
                                            context,
                                          ).inkOpacity(.25),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(colors.chartRadius),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dayKey(day.day) == dayKey(today)
                                      ? 'Сег'
                                      : day.day.day.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.5,
                                    color: AppPalette.of(
                                      context,
                                    ).inkOpacity(.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AwardsView extends StatelessWidget {
  const AwardsView({super.key, required this.awards});

  final List<TaskAward> awards;

  @override
  Widget build(BuildContext context) {
    final got = awards.where((a) => a.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ачивки', style: pageHeading(context)),
        const SizedBox(height: 4),
        Text('Открыто $got из ${awards.length}', style: captionStyle(context)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: awards.isEmpty ? 0 : got / awards.length,
            minHeight: 8,
            color: AppPalette.of(context).strong,
            backgroundColor: AppPalette.of(context).sand,
          ),
        ),
        const SizedBox(height: 20),
        for (var row = 0; row < (awards.length / 2).ceil(); row++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _AwardCard(awards[row * 2])),
                const SizedBox(width: 12),
                Expanded(
                  child: row * 2 + 1 < awards.length
                      ? _AwardCard(awards[row * 2 + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AwardCard extends StatelessWidget {
  const _AwardCard(this.award);

  final TaskAward award;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: colors.panel(
        color: award.unlocked ? colors.card : colors.sand,
        flat: colors.design == AppDesign.editorial,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: colors.playful
                ? (award.glyph.length.isEven ? .08 : -.08)
                : 0,
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: award.unlocked ? colors.accent : colors.done,
                border: Border.all(
                  color: award.unlocked
                      ? colors.strong.withValues(alpha: .3)
                      : colors.line,
                ),
                borderRadius: BorderRadius.circular(
                  colors.design == AppDesign.strict
                      ? 5
                      : colors.playful
                      ? 18
                      : 28,
                ),
              ),
              child: Text(
                award.glyph,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: award.unlocked
                      ? const Color(0xFF252825)
                      : colors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            award.title,
            textAlign: TextAlign.center,
            style: colors.heading.copyWith(
              fontSize: 15,
              height: 1.4,
              color: award.unlocked ? colors.ink : colors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            award.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.5, color: colors.muted),
          ),
          const SizedBox(height: 8),
          Icon(
            award.unlocked ? Icons.check_circle_outline : Icons.lock_outline,
            size: 16,
            color: award.unlocked ? colors.strong : colors.muted,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/task_statistics.dart';
import '../theme/palette.dart';
import '../widgets/design_icon.dart';
import '../widgets/progress_ring.dart';
import '../widgets/task_card.dart';

const pageHeading = TextStyle(
  fontSize: 34,
  height: 1.25,
  fontWeight: FontWeight.w400,
);

TextStyle captionStyle(BuildContext context, [double opacity = .55]) =>
    TextStyle(
      fontSize: 14,
      height: 20 / 14,
      color: AppPalette.of(context).inkOpacity(opacity),
    );

BoxDecoration softCard(
  BuildContext context, {
  double radius = 24,
  Color? color,
}) => BoxDecoration(
  color: color ?? AppPalette.of(context).card,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppPalette.of(context).inkOpacity(.05)),
);

class ArchiveView extends StatefulWidget {
  const ArchiveView({
    super.key,
    required this.days,
    required this.tasks,
    required this.today,
    required this.onToggle,
    required this.onEdit,
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
          const Expanded(child: Text('Архив', style: pageHeading)),
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
              decoration: softCard(context),
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
                              borderRadius: BorderRadius.circular(16),
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
                          for (final task in tasks)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  TaskCheck(
                                    size: 20,
                                    title: task.title,
                                    done: task.done,
                                    onTap: widget.busy
                                        ? null
                                        : () => widget.onToggle(task),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: widget.busy
                                          ? null
                                          : () => widget.onEdit(task),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 48,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              task.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 20 / 14,
                                                color: task.done
                                                    ? AppPalette.of(
                                                        context,
                                                      ).inkOpacity(.65)
                                                    : AppPalette.of(
                                                        context,
                                                      ).ink,
                                                decoration: task.done
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
    this.onSettings,
  });

  final VoidCallback? onSettings;
  final TaskStatistics statistics;
  final DateTime today;
  final StatisticsMode mode;
  final ValueChanged<StatisticsMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
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
            Expanded(child: Text('Статистика', style: pageHeading.copyWith(fontSize: 28))),
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
                borderRadius: BorderRadius.circular(16),
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
          decoration: BoxDecoration(
            color: AppPalette.of(context).cream,
            border: Border.all(color: AppPalette.of(context).inkOpacity(.1)),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              ProgressRing(
                percent: stats.percent,
                size: 116,
                stroke: 12,
                fontSize: 30,
                child: showCount
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${stats.completed}',
                            style: const TextStyle(fontSize: 30, height: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'из ${stats.total}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppPalette.of(context).inkOpacity(.55),
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
                      style: captionStyle(context, .65),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.percent >= 70
                          ? 'Отличный темп!'
                          : 'Есть куда расти',
                      style: const TextStyle(fontSize: 20, height: 1.375),
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
                  decoration: softCard(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i == 0 ? 'Всего задач' : 'Выполнено',
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.of(context).inkOpacity(.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        i == 0
                            ? '${stats.total}'
                            : showCount
                            ? '${stats.completed}'
                            : '${stats.percent}%',
                        style: const TextStyle(fontSize: 36, height: 1.11),
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
          decoration: softCard(context),
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
                height: 114 + MediaQuery.textScalerOf(context).scale(10) * 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, day) in days.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          label:
                              '${DateFormat('d MMMM', 'ru').format(day.day)}: ${day.completed} из ${day.total}',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                showCount
                                    ? '${day.completed}'
                                    : '${(day.ratio * 100).round()}%',
                                key: ValueKey('chart-value-${dayKey(day.day)}'),
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.of(context).inkOpacity(.6),
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
                                      : AppPalette.of(context).inkOpacity(.25),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
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
                                  color: AppPalette.of(context).inkOpacity(.45),
                                ),
                              ),
                            ],
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
        const Text('Ачивки', style: pageHeading),
        const SizedBox(height: 4),
        Text('Открыто $got из ${awards.length}', style: captionStyle(context)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: awards.isEmpty ? 0 : got / awards.length,
            minHeight: 8,
            color: AppPalette.of(context).ink,
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: award.unlocked
          ? AppPalette.of(context).card
          : AppPalette.of(context).sand.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: award.unlocked
                ? AppPalette.of(context).cream
                : AppPalette.of(context).inkOpacity(.1),
            border: award.unlocked
                ? Border.all(color: AppPalette.of(context).inkOpacity(.15))
                : null,
            boxShadow: award.unlocked
                ? const [
                    BoxShadow(
                      color: Color(0x402B2116),
                      blurRadius: 14,
                      spreadRadius: -4,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            award.glyph,
            style: TextStyle(
              fontSize: 18,
              height: 1.55,
              color: award.unlocked
                  ? AppPalette.of(context).ink
                  : AppPalette.of(context).inkOpacity(.3),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          award.title,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w700,
            color: award.unlocked
                ? AppPalette.of(context).ink
                : AppPalette.of(context).inkOpacity(.45),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          award.description,
          style: TextStyle(
            fontSize: 12,
            height: 1.375,
            color: AppPalette.of(context).inkOpacity(.5),
          ),
        ),
      ],
    ),
  );
}

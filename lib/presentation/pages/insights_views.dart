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
TextStyle captionStyle([double opacity = .55]) =>
    TextStyle(fontSize: 14, height: 20 / 14, color: inkOpacity(opacity));

BoxDecoration softCard({double radius = 24, Color color = card}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: inkOpacity(.05)),
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
  });
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
      const Text('Архив', style: pageHeading),
      const SizedBox(height: 4),
      Text('Прошедшие дни можно редактировать', style: captionStyle()),
      const SizedBox(height: 20),
      if (widget.days.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'Здесь появится история твоих дней.',
            style: captionStyle(.45),
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
              decoration: softCard(),
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
                                sage,
                                peach,
                                percent.clamp(12, 100) / 100,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$percent%',
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.55,
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
                                    color: inkOpacity(.5),
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
                              color: inkOpacity(.3),
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
                                    done: task.done,
                                    onTap: () => widget.onToggle(task),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => widget.onEdit(task),
                                      behavior: HitTestBehavior.opaque,
                                      child: Text(
                                        task.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 20 / 14,
                                          color: task.done
                                              ? inkOpacity(.5)
                                              : ink,
                                          decoration: task.done
                                              ? TextDecoration.lineThrough
                                              : null,
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

class StatisticsView extends StatelessWidget {
  const StatisticsView({
    super.key,
    required this.statistics,
    required this.today,
  });
  final TaskStatistics statistics;
  final DateTime today;
  @override
  Widget build(BuildContext context) {
    final stats = statistics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Статистика', style: pageHeading),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: peach,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              ProgressRing(
                percent: stats.percent,
                size: 116,
                stroke: 12,
                fontSize: 30,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Процент выполнения', style: captionStyle(.65)),
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
                  decoration: softCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i == 0 ? 'Всего задач' : 'Выполнено',
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: inkOpacity(.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${i == 0 ? stats.total : stats.completed}',
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
          decoration: softCard(),
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
                height: 144,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, day) in stats.week.skip(1).indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          label:
                              '${DateFormat('d MMMM', 'ru').format(day.day)}: ${day.completed} из ${day.total}',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${(day.ratio * 100).round()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.5,
                                  fontWeight: FontWeight.w700,
                                  color: inkOpacity(.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height:
                                    (144 * (day.ratio < .04 ? .04 : day.ratio))
                                        .clamp(0, 98),
                                decoration: const BoxDecoration(
                                  color: peach,
                                  borderRadius: BorderRadius.vertical(
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
                                  color: inkOpacity(.45),
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
        Text('Открыто $got из ${awards.length}', style: captionStyle()),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: awards.isEmpty ? 0 : got / awards.length,
            minHeight: 8,
            color: peach,
            backgroundColor: sand,
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
      color: award.unlocked ? card : sand.withValues(alpha: .6),
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
            color: award.unlocked ? peach : inkOpacity(.1),
            boxShadow: award.unlocked
                ? const [
                    BoxShadow(
                      color: Color(0xCCFFAA46),
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
              color: award.unlocked ? ink : inkOpacity(.3),
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
            color: award.unlocked ? ink : inkOpacity(.45),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          award.description,
          style: TextStyle(fontSize: 12, height: 1.375, color: inkOpacity(.5)),
        ),
      ],
    ),
  );
}

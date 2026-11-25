import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/task_statistics.dart';
import '../theme/palette.dart';
import '../widgets/animated_task_list.dart';
import '../widgets/design_icon.dart';
import '../widgets/progress_ring.dart';
import '../widgets/reference_widgets.dart';

class ArchiveView extends StatefulWidget {
  const ArchiveView({
    super.key,
    required this.days,
    required this.tasks,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
    required this.onChooseDate,
    required this.busy,
    required this.onBackups,
  });

  final bool busy;
  final VoidCallback onBackups;
  final List<String> days;
  final List<Task> tasks;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final ValueChanged<DateTime> onAdd;
  final VoidCallback onChooseDate;

  @override
  State<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends State<ArchiveView> {
  String? open;

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    final months = <DateTime, List<String>>{};
    for (final day in widget.days) {
      final date = DateTime.parse(day);
      months.putIfAbsent(DateTime(date.year, date.month), () => []).add(day);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignHeader(
          eyebrow: 'ВСЁ ОСТАЁТСЯ С ВАМИ',
          title: 'Архив',
          action: IconButton(
            tooltip: 'Копии задач',
            onPressed: widget.onBackups,
            icon: DesignIcon(DesignSymbol.archive, size: 22, color: c.muted),
          ),
        ),
        if (months.isEmpty) ...[
          Text(
            'Здесь появится история твоих дней.',
            style: designText(13, color: c.muted),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onChooseDate,
              child: const Text('Открыть дату'),
            ),
          ),
        ],
        for (final (index, entry) in months.entries.indexed) ...[
          if (index > 0) const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  capitalize(DateFormat('LLLL yyyy', 'ru').format(entry.key)),
                  style: designText(13, weight: 550),
                ),
              ),
              Text(
                dayCount(entry.value.length),
                style: designText(10, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (c.lined) Divider(height: 1, color: c.line),
          for (final (index, day) in entry.value.indexed) ...[
            if (!c.lined && index > 0) const SizedBox(height: 10),
            archiveDay(context, c, day),
          ],
        ],
      ],
    );
  }

  Widget archiveDay(BuildContext context, AppPalette c, String day) {
    final tasks = widget.tasks.where((task) => task.day == day).toList();
    final done = tasks.where((task) => task.done).length;
    final percent = tasks.isEmpty ? 0 : (done / tasks.length * 100).round();
    final date = DateTime.parse(day);
    final showBadge = percent == 100 && !c.editorial;
    return Container(
      decoration: c.panel(flat: c.lined),
      child: Column(
        children: [
          InkWell(
            key: ValueKey('archive-$day'),
            onTap: () => setState(() => open = open == day ? null : day),
            child: Container(
              constraints: BoxConstraints(minHeight: c.lined ? 85 : 76),
              padding: EdgeInsets.symmetric(
                vertical: c.strict ? 15 : 17,
                horizontal: c.editorial
                    ? 0
                    : c.strict
                    ? 2
                    : 15,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMMM', 'ru').format(date),
                          style: designText(
                            c.editorial ? 16 : 14,
                            font: c.editorial ? 'Literata' : 'Golos Text',
                            weight: c.editorial ? 400 : 500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${capitalize(DateFormat('EEEE', 'ru').format(date))} · $done из ${tasks.length} задач',
                          style: designText(12, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: showBadge ? const EdgeInsets.all(5) : null,
                    decoration: showBadge
                        ? BoxDecoration(
                            color: c.strict ? c.accent : c.cream,
                            borderRadius: BorderRadius.circular(6),
                          )
                        : null,
                    child: Text(
                      '$percent%',
                      style: designText(
                        c.editorial
                            ? 19
                            : c.strict
                            ? (showBadge ? 21 : 23)
                            : (showBadge ? 14 : 16),
                        font: c.editorial ? 'Literata' : 'DM Sans',
                        spacing: c.strict ? -1 : 0,
                        color: c.strict && showBadge && c.dark
                            ? c.paper
                            : c.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: open == day ? .25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: DesignIcon(
                      DesignSymbol.chevron,
                      size: 18,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open == day)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Column(
                children: [
                  AnimatedTaskList(
                    key: ValueKey('archive-tasks-$day'),
                    tasks: tasks,
                    busy: widget.busy,
                    compact: true,
                    onToggle: widget.onToggle,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                  ),
                  SizedBox(
                    height: c.strict
                        ? 20
                        : c.editorial
                        ? 19
                        : 10,
                  ),
                  DesignButton(
                    label: 'Добавить задачу',
                    icon: DesignSymbol.plus,
                    onPressed: widget.busy ? null : () => widget.onAdd(date),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String capitalize(String value) => value[0].toUpperCase() + value.substring(1);

String dayCount(int count) {
  final last = count % 10;
  final teens = count % 100 >= 11 && count % 100 <= 14;
  return '$count ${teens
      ? 'дней'
      : last == 1
      ? 'день'
      : last >= 2 && last <= 4
      ? 'дня'
      : 'дней'}';
}

enum StatisticsMode { count, percent }

enum ChartPeriod {
  week('Неделя'),
  month('Месяц'),
  custom('Период');

  const ChartPeriod(this.label);
  final String label;
}

class StatisticsView extends StatelessWidget {
  const StatisticsView({
    super.key,
    required this.statistics,
    required this.range,
    required this.period,
    required this.onPeriodChanged,
    required this.mode,
    required this.onModeChanged,
    required this.onOpenDay,
  });

  final TaskStatistics statistics;
  final DateTimeRange range;
  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onPeriodChanged;
  final StatisticsMode mode;
  final ValueChanged<StatisticsMode> onModeChanged;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DesignHeader(
          eyebrow: 'МАЛЕНЬКИЕ ШАГИ СЧИТАЮТСЯ',
          title: 'Статистика',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 23),
          decoration: BoxDecoration(
            color: c.hero,
            borderRadius: BorderRadius.circular(c.radius),
            border: c.editorial ? Border.all(color: c.line) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Общий прогресс',
                      style: designText(12, color: c.onHero, height: 2),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${statistics.percent}'),
                          TextSpan(
                            text: '%',
                            style: designText(
                              25,
                              font: c.editorial ? 'Literata' : 'DM Sans',
                            ),
                          ),
                        ],
                      ),
                      style: designText(
                        c.editorial ? 43 : 49,
                        font: c.editorial ? 'Literata' : 'DM Sans',
                        weight: c.editorial ? 400 : 500,
                        height: 1.2,
                        spacing: -2,
                        color: c.onHero,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Хороший ритм. Так держать.',
                      style: designText(
                        11,
                        color: c.strict && !c.dark
                            ? const Color(0xFFB2B8A7)
                            : c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ProgressRing(
                percent: statistics.percent,
                size: 87,
                stroke: 8,
                color: c.heroAccent,
                trackColor: c.playful && !c.dark
                    ? const Color(0xFFD9CDEB)
                    : c.inkOpacity(.07),
                rounded: false,
                child: Transform.rotate(
                  angle: c.playful ? math.pi / 15 : -math.pi / 4,
                  child: DesignIcon(
                    c.playful ? DesignSymbol.star : DesignSymbol.arrow,
                    size: 31,
                    color: c.strict
                        ? c.accent
                        : c.playful
                        ? const Color(0xFF9174BD)
                        : c.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: statTile(
                  c,
                  DesignSymbol.check,
                  statistics.completed,
                  'задачи выполнены',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: statTile(
                  c,
                  DesignSymbol.flame,
                  statistics.streak,
                  'текущая серия',
                  suffix: ' дней',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        chart(context, c),
      ],
    );
  }

  Widget statTile(
    AppPalette c,
    DesignSymbol icon,
    int value,
    String label, {
    String? suffix,
  }) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: c.editorial
          ? null
          : c.playful
          ? (c.dark
                ? c.cream
                : suffix == null
                ? c.positive
                : c.celebration)
          : c.card,
      borderRadius: c.editorial ? null : BorderRadius.circular(c.radius),
      border: c.editorial
          ? Border(bottom: BorderSide(color: c.line))
          : Border.all(
              color: c.playful && !c.dark
                  ? suffix == null
                        ? const Color(0xFFE1E7D5)
                        : const Color(0xFFF0DFD2)
                  : c.line,
            ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignIcon(icon, size: 19, color: c.muted),
        const SizedBox(height: 9),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$value'),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: designText(
                    16,
                    font: c.editorial ? 'Literata' : 'DM Sans',
                  ),
                ),
            ],
          ),
          style: designText(
            28,
            height: 1.5,
            weight: c.editorial ? 400 : 500,
            font: c.editorial ? 'Literata' : 'DM Sans',
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: designText(12, color: c.muted, height: 2)),
      ],
    ),
  );

  Widget chart(BuildContext context, AppPalette c) {
    final first = range.start;
    final last = range.end;
    final length = calendarDayNumber(last) - calendarDayNumber(first) + 1;
    final scale = math.max(5, statistics.maxCompletedBetween(first, last));
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dates = first == last
        ? dateFormat.format(first)
        : '${dateFormat.format(first)} – ${dateFormat.format(last)}';
    return Container(
      padding: EdgeInsets.fromLTRB(
        c.editorial ? 0 : 17,
        19,
        c.editorial ? 0 : 17,
        15,
      ),
      decoration: c.editorial
          ? null
          : BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(c.radius),
              border: Border.all(color: c.line),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ваш ритм',
                  style: designText(
                    c.editorial ? 18 : 14,
                    font: c.editorial ? 'Literata' : 'Golos Text',
                    weight: c.editorial ? 400 : 550,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dates,
                  textAlign: TextAlign.end,
                  style: designText(11, color: c.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              for (final option in ChartPeriod.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: option == period,
                  showCheckmark: false,
                  onSelected: (_) => onPeriodChanged(option),
                  selectedColor: c.selectedSegment,
                  labelStyle: designText(
                    12,
                    color: option == period ? c.onSelectedSegment : c.ink,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 195,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.sand,
              borderRadius: BorderRadius.circular(c.strict ? 3 : 9),
            ),
            child: Row(
              children: [
                for (final (value, label) in [
                  (StatisticsMode.count, 'Задачи'),
                  (StatisticsMode.percent, 'Проценты'),
                ])
                  Expanded(
                    child: Semantics(
                      selected: mode == value,
                      button: true,
                      child: InkWell(
                        key: ValueKey('chart-mode-${value.name}'),
                        onTap: () => onModeChanged(value),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          decoration: mode == value
                              ? BoxDecoration(
                                  color: c.selectedSegment,
                                  borderRadius: BorderRadius.circular(
                                    c.strict ? 2 : 6,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                )
                              : null,
                          child: Text(
                            label,
                            style: designText(
                              10,
                              color: mode == value
                                  ? c.onSelectedSegment
                                  : c.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final labelHeight =
                  MediaQuery.textScalerOf(context).scale(10) * 1.5;
              final top = math.max(33.0, labelHeight + 6);
              return SizedBox(
                height: top + 100 + 9 + labelHeight.ceil() + 6,
                child: ListView.builder(
                  key: PageStorageKey(range),
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  physics: length <= 7
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: EdgeInsets.only(top: top),
                  itemExtent: constraints.maxWidth / math.min(7, length),
                  itemCount: length,
                  itemBuilder: (context, index) {
                    final date = DateTime(
                      first.year,
                      first.month,
                      first.day + index,
                    );
                    return bar(
                      context,
                      c,
                      statistics.progressOn(date),
                      scale,
                      index == length - 1,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              length > 7
                  ? 'Листайте график по горизонтали. Нажмите на столбик, чтобы открыть день.'
                  : 'Нажмите на столбик, чтобы открыть день',
              textAlign: TextAlign.center,
              style: designText(10, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget bar(
    BuildContext context,
    AppPalette c,
    DayProgress day,
    int scale,
    bool last,
  ) {
    final count = mode == StatisticsMode.count;
    final ratio = count ? day.completed / scale : day.ratio;
    final dayId = dayKey(day.day);
    final color = c.strict
        ? last
              ? c.ink
              : c.dark
              ? c.line
              : const Color(0xFFD8DCCB)
        : c.editorial
        ? last
              ? const Color(0xFF648691)
              : const Color(0xFFC9D8DB)
        : last
        ? c.accent
        : c.cream;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label:
          'Открыть ${DateFormat('d MMMM', 'ru').format(day.day)}: ${day.completed} выполненных задач',
      button: true,
      child: InkWell(
        key: ValueKey('chart-day-$dayId'),
        onTap: () => onOpenDay(day.day),
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  for (final y in [32.0, 65.0, 98.0])
                    Positioned(
                      bottom: y,
                      left: 0,
                      right: 0,
                      child: ColoredBox(
                        color: c.line,
                        child: const SizedBox(height: 1),
                      ),
                    ),
                  AnimatedContainer(
                    key: ValueKey('chart-bar-$dayId'),
                    duration: animate
                        ? const Duration(milliseconds: 300)
                        : Duration.zero,
                    height: 100 * ratio,
                    width: 31,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: c.lined
                          ? BorderRadius.circular(1)
                          : const BorderRadius.vertical(
                              top: Radius.circular(6),
                              bottom: Radius.circular(2),
                            ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: animate
                        ? const Duration(milliseconds: 300)
                        : Duration.zero,
                    bottom: 100 * ratio + 6,
                    left: 0,
                    right: 0,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        count
                            ? '${day.completed}'
                            : '${(day.ratio * 100).round()}%',
                        key: ValueKey('chart-value-$dayId'),
                        style: designText(10, color: c.muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                range.start.month == range.end.month &&
                        range.start.year == range.end.year
                    ? '${day.day.day}'
                    : DateFormat('d.MM').format(day.day),
                style: designText(10, color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AwardsView extends StatelessWidget {
  const AwardsView({super.key, required this.awards, required this.onSettings});
  final VoidCallback onSettings;
  final List<TaskAward> awards;

  static const symbols = <String, DesignSymbol>{
    '1': DesignSymbol.leaf,
    '10': DesignSymbol.bolt,
    '3д': DesignSymbol.flame,
    '100': DesignSymbol.target,
    '7д': DesignSymbol.star,
    '50': DesignSymbol.award,
    '25': DesignSymbol.bolt,
    '250': DesignSymbol.star,
    '5д': DesignSymbol.target,
    '14д': DesignSymbol.flame,
    '30д': DesignSymbol.moon,
    '13д': DesignSymbol.award,
    '✓': DesignSymbol.star,
  };

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    final got = awards.where((award) => award.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignHeader(
          eyebrow: 'ЕСТЬ ЧЕМ ГОРДИТЬСЯ',
          action: IconButton(
            tooltip: 'Настройки',
            onPressed: onSettings,
            icon: Icon(Icons.settings_outlined, size: 22, color: c.muted),
          ),
          title: c.editorial ? 'Мои открытия' : 'Ачивки',
          subtitle: c.playful
              ? 'Обычные дела. Необычный ты.'
              : 'Не гонка. Ваша личная коллекция.',
          mark: const DesignIcon(
            DesignSymbol.star,
            size: 28,
            color: Color(0xFFD7A76C),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: c.cream,
            borderRadius: BorderRadius.circular(c.editorial ? 3 : c.radius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$got ',
                        style: designText(20, weight: 550),
                      ),
                      TextSpan(text: 'из ${awards.length} открыто'),
                    ],
                  ),
                  key: const ValueKey('award-progress'),
                  style: designText(12),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 115,
                child: LinearProgressIndicator(
                  value: awards.isEmpty ? 0 : got / awards.length,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(5),
                  color: Color.lerp(c.accent, Colors.black, .12),
                  backgroundColor: c.inkOpacity(.08),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        Table(
          columnWidths: const {1: FixedColumnWidth(11)},
          defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
          children: [
            for (var i = 0; i < awards.length; i += 2) ...[
              if (i > 0)
                const TableRow(
                  children: [SizedBox(height: 11), SizedBox(), SizedBox()],
                ),
              TableRow(
                children: [
                  awardTile(context, c, awards[i], i),
                  const SizedBox(),
                  i + 1 < awards.length
                      ? awardTile(context, c, awards[i + 1], i + 1)
                      : const SizedBox(),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget awardTile(BuildContext context, AppPalette c, TaskAward award, int i) {
    final radius = BorderRadius.circular(c.editorial ? 3 : c.radius);
    return Material(
      color: c.editorial
          ? Colors.transparent
          : award.unlocked
          ? c.playful && !c.dark
                ? const Color(0xFFFFFDF8)
                : c.card
          : c.sand,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: c.line),
        borderRadius: radius,
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () => showDesignSheet<void>(
          context,
          builder: (_) => DesignSheet(
            title: 'Маленькая победа',
            children: [
              const SizedBox(height: 20),
              Center(child: medal(c, award, i, detail: true)),
              const SizedBox(height: 20),
              Text(
                award.title,
                textAlign: TextAlign.center,
                style: c.heading.copyWith(fontSize: 25),
              ),
              const SizedBox(height: 10),
              Text(
                award.description,
                textAlign: TextAlign.center,
                style: designText(13, color: c.muted),
              ),
              const SizedBox(height: 25),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.cream,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    award.unlocked
                        ? 'Уже в вашей коллекции'
                        : 'Всё впереди. В своём ритме.',
                    textAlign: TextAlign.center,
                    style: designText(12, color: c.muted),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: c.strict ? 163 : 167),
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
          decoration: c.playful
              ? BoxDecoration(
                  borderRadius: radius,
                  border: Border(bottom: BorderSide(color: c.line, width: 3)),
                )
              : null,
          child: Column(
            children: [
              medal(c, award, i),
              const SizedBox(height: 10),
              Text(
                award.title,
                textAlign: TextAlign.center,
                style: designText(
                  12,
                  height: 1.4,
                  weight: c.editorial ? 500 : 550,
                  font: c.editorial ? 'Literata' : 'Golos Text',
                  color: award.unlocked ? c.ink : c.muted,
                ),
              ),
              const SizedBox(height: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 125),
                child: Text(
                  award.description,
                  textAlign: TextAlign.center,
                  style: designText(10, color: c.muted),
                ),
              ),
              if (award.unlocked) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DesignIcon(DesignSymbol.check, size: 11, color: c.muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Открыто',
                        style: designText(10, color: c.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget medal(AppPalette c, TaskAward award, int i, {bool detail = false}) {
    final (background, ink) = switch (i) {
      1 => (const Color(0xFFE6DFF4), const Color(0xFF8A70AE)),
      2 => (const Color(0xFFE2EBD5), const Color(0xFF789454)),
      3 => (const Color(0xFFF6DBD2), const Color(0xFFB87860)),
      _ => (const Color(0xFFFFE1B5), const Color(0xFFA4753E)),
    };
    final size = detail ? 94.0 : 57.0;
    final fill = !award.unlocked
        ? c.line
        : c.strict
        ? c.accent
        : c.editorial
        ? const Color(0xFFE3E9E4)
        : background;
    final iconColor = !award.unlocked
        ? c.muted
        : c.strict
        ? (c.dark ? c.paper : c.ink)
        : c.editorial
        ? const Color(0xFF6F8988)
        : ink;
    final symbol = award.title == 'Легенда'
        ? DesignSymbol.star
        : symbols[award.glyph] ?? DesignSymbol.award;
    return Transform.rotate(
      angle: !c.playful
          ? 0
          : (i == 1
                    ? 6
                    : i == 2
                    ? 5
                    : -6) *
                math.pi /
                180,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(
                    c.strict
                        ? 5
                        : c.playful
                        ? 21
                        : size / 2,
                  ),
                  border: c.editorial
                      ? Border.all(
                          color: award.unlocked
                              ? const Color(0xFFB6C6BD)
                              : c.line,
                        )
                      : null,
                ),
                child: DesignIcon(
                  symbol,
                  size: detail ? 48 : 33,
                  color: iconColor,
                ),
              ),
            ),
            if (c.editorial)
              Positioned.fill(
                left: 3,
                right: 3,
                top: 3,
                bottom: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.paper, width: 3),
                  ),
                ),
              ),
            if (!award.unlocked && !detail)
              Positioned(
                right: -1,
                bottom: 0,
                child: Container(
                  width: 19,
                  height: 19,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.line),
                  ),
                  child: DesignIcon(
                    DesignSymbol.lock,
                    size: 11,
                    color: c.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../controllers/planner_controller.dart';
import '../theme/palette.dart';
import '../widgets/design_icon.dart';
import '../widgets/reference_widgets.dart';
import '../widgets/task_editor.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key, required this.planner});
  final PlannerController planner;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: planner,
    builder: (context, _) {
      final c = AppPalette.of(context);
      final days = planner.futureDays;
      return DesignSheet(
        title: 'Будущие планы',
        children: [
          Text(
            'Освободите голову — оставьте планы здесь.',
            style: designText(12, height: 1.8, color: c.muted),
          ),
          const SizedBox(height: 23),
          if (days.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 30),
              child: Column(
                children: [
                  DesignIcon(DesignSymbol.calendar, size: 36, color: c.muted),
                  const SizedBox(height: 13),
                  Text(
                    'Будущее ещё не расписано',
                    textAlign: TextAlign.center,
                    style: designText(15),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'Выберите день и добавьте первый план.',
                    textAlign: TextAlign.center,
                    style: designText(11, color: c.muted),
                  ),
                ],
              ),
            ),
          for (final day in days)
            SheetAction(
              icon: DesignSymbol.calendar,
              label: DateFormat('d MMMM', 'ru').format(DateTime.parse(day)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${planner.tasks.where((task) => task.day == day).length} задач',
                    style: designText(11, color: c.muted),
                  ),
                  const SizedBox(width: 13),
                  DesignIcon(DesignSymbol.chevron, size: 17, color: c.muted),
                ],
              ),
              onTap: () => Navigator.pop(context, DateTime.parse(day)),
            ),
          const SizedBox(height: 6),
          DesignButton(
            label: 'Выбрать день',
            icon: DesignSymbol.plus,
            primary: true,
            onPressed: () async {
              final date = await showDesignSheet<DateTime>(
                context,
                builder: (_) =>
                    CalendarSheet(initialDate: nextDay(planner.today)),
              );
              if (date != null && context.mounted) Navigator.pop(context, date);
            },
          ),
        ],
      );
    },
  );
}

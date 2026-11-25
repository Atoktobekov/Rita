import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';
import '../theme/palette.dart';
import 'design_icon.dart';
import 'reference_widgets.dart';

Future<DateTime?> pickDay(BuildContext context, DateTime current) =>
    showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: 'Выберите день',
    );

class TaskEditor extends StatefulWidget {
  const TaskEditor({
    super.key,
    this.task,
    required this.day,
    required this.onSave,
  });

  final Future<void> Function(Task) onSave;
  final Task? task;
  final DateTime day;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.task?.title);
  late DateTime day = widget.day;

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  bool saving = false;
  String? error;

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    final result =
        widget.task?.copyWith(title: title.text.trim(), day: dayKey(day)) ??
        Task(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.text.trim(),
          day: dayKey(day),
        );
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave(result);
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Не удалось сохранить задачу. Текст сохранён в форме — попробуйте ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    return PopScope(
      canPop: !saving,
      child: AbsorbPointer(
        absorbing: saving,
        child: Form(
          key: form,
          child: DesignSheet(
            title: widget.task == null
                ? 'Новая задача'
                : 'Редактировать задачу',
            children: [
              const SizedBox(height: 11),
              Text('Название задачи', style: designText(11, color: c.muted)),
              const SizedBox(height: 9),
              TextFormField(
                controller: title,
                maxLength: 200,
                minLines: 3,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: designText(15, height: 1.7),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: c.card,
                  contentPadding: const EdgeInsets.all(15),
                  border: dateFieldBorder(c),
                  enabledBorder: dateFieldBorder(c),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Напиши название задачи'
                    : value.trim().length > 200
                    ? 'Не больше 200 символов'
                    : null,
              ),
              const SizedBox(height: 20),
              DateField(
                day: day,
                fieldKey: const ValueKey('editor-date'),
                onChanged: (picked) => setState(() => day = picked),
              ),
              const SizedBox(height: 20),
              Text(
                'Без спешки. План всегда можно изменить.',
                style: designText(12, height: 1.8, color: c.muted),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: designText(
                        12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 26),
              DesignButton(
                primary: true,
                label: saving
                    ? 'Сохранение…'
                    : widget.task == null
                    ? 'Добавить задачу'
                    : 'Сохранить изменения',
                icon: DesignSymbol.check,
                onPressed: saving ? null : save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder dateFieldBorder(AppPalette c) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: c.line),
);

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    this.fieldKey,
    required this.day,
    required this.onChanged,
  });

  final Key? fieldKey;
  final DateTime day;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Дата', style: designText(11, color: c.muted)),
        const SizedBox(height: 9),
        Material(
          color: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.line),
          ),
          child: InkWell(
            key: fieldKey,
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await pickDay(context, day);
              if (picked != null && context.mounted) onChanged(picked);
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd.MM.yyyy').format(day),
                      style: designText(15, height: 1.7),
                    ),
                  ),
                  DesignIcon(DesignSymbol.calendar, size: 18, color: c.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CalendarSheet extends StatefulWidget {
  const CalendarSheet({
    super.key,
    required this.initialDate,
    this.openOnSelection = false,
  });

  final DateTime initialDate;
  final bool openOnSelection;

  @override
  State<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<CalendarSheet> {
  late DateTime day = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    return DesignSheet(
      title: 'Выберите день',
      children: [
        Text(
          'Планы на любой день — в одном месте.',
          style: designText(12, height: 1.8, color: c.muted),
        ),
        const SizedBox(height: 23),
        DateField(
          fieldKey: const ValueKey('calendar-date'),
          day: day,
          onChanged: widget.openOnSelection
              ? (picked) => Navigator.pop(context, picked)
              : (picked) => setState(() => day = picked),
        ),
        if (!widget.openOnSelection) ...[
          const SizedBox(height: 23),
          DesignButton(
            primary: true,
            label: 'Открыть день',
            icon: DesignSymbol.arrow,
            onPressed: () => Navigator.pop(context, day),
          ),
        ],
      ],
    );
  }
}

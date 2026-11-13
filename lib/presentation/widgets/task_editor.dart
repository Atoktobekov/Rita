import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';

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
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AbsorbPointer(
      absorbing: saving,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.task == null
                          ? 'Новая задача'
                          : 'Редактировать задачу',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: title,
                autofocus: true,
                maxLength: 200,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Что нужно сделать?',
                  hintText: 'Например, прочитать 10 страниц',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Напиши название задачи'
                    : value.trim().length > 200
                    ? 'Не больше 200 символов'
                    : null,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('editor-date'),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(DateFormat('d MMMM yyyy', 'ru').format(day)),
                onPressed: () async {
                  final picked = await pickDay(context, day);
                  if (picked != null && mounted) setState(() => day = picked);
                },
              ),
              const SizedBox(height: 16),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(
                    saving
                        ? 'Сохранение…'
                        : widget.task == null
                        ? 'Добавить задачу'
                        : 'Сохранить изменения',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

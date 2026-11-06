import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calendar.dart';
import '../../domain/entities/task.dart';

const categories = ['Личное', 'Работа', 'Здоровье', 'Развитие'];

Future<DateTime?> pickDay(BuildContext context, DateTime current) =>
    showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: 'Выберите день',
    );

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.task, required this.day});
  final Task? task;
  final DateTime day;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.task?.title);
  late String category = widget.task?.category ?? categories.first;
  late DateTime day = widget.day;
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  void save() {
    if (!form.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.task?.copyWith(
            title: title.text.trim(),
            category: category,
            day: dayKey(day),
          ) ??
          Task(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title.text.trim(),
            category: category,
            day: dayKey(day),
          ),
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
                  widget.task == null ? 'Новая задача' : 'Редактировать задачу',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Закрыть',
                onPressed: () => Navigator.pop(context),
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
          const Text('Категория'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: categories
                .map(
                  (c) => ChoiceChip(
                    label: Text(c),
                    selected: category == c,
                    onSelected: (_) => setState(() => category = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: save,
              child: Text(
                widget.task == null ? 'Добавить задачу' : 'Сохранить изменения',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

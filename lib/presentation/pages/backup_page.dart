import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../data/services/backup_files.dart';
import '../../data/services/task_backup.dart';
import '../controllers/planner_controller.dart';
import '../theme/palette.dart';
import '../widgets/design_icon.dart';
import '../widgets/reference_widgets.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.planner, this.files});
  final PlannerController planner;
  final BackupFiles? files;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final files = widget.files ?? BackupFiles();
  TaskBackup? preview;
  bool working = false;
  bool confirming = false;
  String? message;
  bool failed = false;

  Future<void> run(Future<void> Function() action) async {
    if (working) return;
    setState(() {
      working = true;
      message = null;
      failed = false;
    });
    try {
      await action();
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          message = error.message;
          failed = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          message =
              'Не удалось завершить операцию. Ваши задачи сохранены. Повторите попытку.';
          failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<bool> confirm(String title, String description) async {
    setState(() => confirming = true);
    try {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(description),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Подтвердить'),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      if (mounted) setState(() => confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.planner,
    builder: (context, _) {
      final planner = widget.planner;
      final enabled = !working && !planner.busy;
      final c = AppPalette.of(context);
      return PopScope(
        canPop: !working,
        child: DesignSheet(
          title: 'Ваши задачи — с вами',
          children: [
            Text(
              'Скачайте копию или восстановите задачи из JSON-файла.',
              style: designText(12, height: 1.8, color: c.muted),
            ),
            const SizedBox(height: 23),
            if (planner.damagedCount > 0) ...[
              Text(
                'Не удалось прочитать записей: ${planner.damagedCount}. Они сохранены отдельно на устройстве. В файл попадут только исправные задачи.',
              ),
              const SizedBox(height: 16),
            ],
            SheetAction(
              onTap: enabled
                  ? () => run(() async {
                      final saved = await files.save(planner.tasks);
                      if (mounted && saved) {
                        setState(
                          () => message = kIsWeb
                              ? 'Файл передан браузеру для скачивания'
                              : 'Копия задач сохранена',
                        );
                      }
                    })
                  : null,
              icon: DesignSymbol.download,
              label: 'Экспортировать JSON',
              trailing: DesignIcon(
                DesignSymbol.arrow,
                size: 18,
                color: c.muted,
              ),
            ),
            SheetAction(
              onTap: enabled
                  ? () => run(() async {
                      setState(() => preview = null);
                      final selected = await files.pick();
                      if (mounted) setState(() => preview = selected);
                    })
                  : null,
              icon: DesignSymbol.upload,
              label: 'Импортировать JSON',
              trailing: DesignIcon(
                DesignSymbol.arrow,
                size: 18,
                color: c.muted,
              ),
            ),
            if (preview case final copy?) ...[
              const SizedBox(height: 20),
              Text(
                'Предпросмотр копии',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Создана: ${DateFormat('d MMMM yyyy, HH:mm', 'ru').format(copy.createdAt.toLocal())}',
              ),
              Text(
                'Задач: ${copy.tasks.length}; выполнено: ${copy.tasks.where((t) => t.done).length}',
              ),
              if (copy.tasks.isNotEmpty)
                Text(
                  'Даты: ${(copy.tasks.map((t) => t.day).toList()..sort()).first} — ${(copy.tasks.map((t) => t.day).toList()..sort()).last}',
                ),
              const SizedBox(height: 8),
              const Text(
                'Импорт заменит все текущие задачи. Предыдущая версия будет сохранена на устройстве и доступна для восстановления.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('apply-import'),
                onPressed: enabled
                    ? () => run(() async {
                        if (!await confirm(
                          'Заменить задачи?',
                          'Текущих задач: ${planner.tasks.length}. В копии: ${copy.tasks.length}. Перед заменой сохраним предыдущую версию.',
                        )) {
                          return;
                        }
                        await planner.importTasks(copy.tasks);
                        if (mounted) {
                          setState(() {
                            preview = null;
                            message =
                                'Задачи импортированы. Предыдущую версию можно восстановить.';
                          });
                        }
                      })
                    : null,
                child: const Text('Заменить задачи из копии'),
              ),
            ],
            if (planner.canRestore) ...[
              const SizedBox(height: 24),
              Text(
                'Предыдущая версия',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Хранится последняя версия перед импортом. Восстановление меняет её местами с текущими задачами, поэтому его тоже можно отменить.',
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: enabled
                    ? () => run(() async {
                        if (!await confirm(
                          'Восстановить предыдущую версию?',
                          'Текущие задачи будут сохранены вместо неё.',
                        )) {
                          return;
                        }
                        await planner.restoreBackup();
                        if (mounted) {
                          setState(() {
                            preview = null;
                            message = 'Предыдущая версия восстановлена';
                          });
                        }
                      })
                    : null,
                child: const Text('Восстановить предыдущую версию'),
              ),
            ],
            if (working && !confirming)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (message != null)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    message!,
                    style: TextStyle(
                      color: failed
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../theme/palette.dart';
import 'design_icon.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppPalette.of(context).paper,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const ValueKey('task-edit'),
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Редактировать'),
                enabled: onEdit != null,
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                key: const ValueKey('task-delete'),
                leading: const Icon(Icons.delete_outline),
                title: const Text('Удалить'),
                enabled: onDelete != null,
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') onEdit?.call();
    if (action == 'delete') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final actions = onEdit != null || onDelete != null
        ? () => _showActions(context)
        : null;
    final radius = BorderRadius.circular(colors.lined ? 0 : colors.radius);
    return Semantics(
      label: task.title,
      hint: 'Нажмите, чтобы изменить выполнение. Удерживайте для действий.',
      checked: task.done,
      enabled: onToggle != null,
      onTap: onToggle,
      onLongPress: actions,
      excludeSemantics: true,
      child: Container(
        decoration: colors.panel(
          color: task.done ? colors.done : colors.card,
          flat: colors.lined,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('task-card-${task.id}'),
            onTap: onToggle,
            onLongPress: actions,
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsets.fromLTRB(colors.lined ? 2 : 16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: task.done ? colors.muted : colors.ink,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    key: ValueKey('check-${task.id}'),
                    width: 48,
                    height: 48,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: colors.lined ? 22 : 26,
                        height: colors.lined ? 22 : 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.done ? colors.action : Colors.transparent,
                          border: Border.all(
                            color: task.done ? colors.action : colors.muted,
                            width: 1.6,
                          ),
                        ),
                        child: task.done
                            ? Center(
                                child: DesignIcon(
                                  DesignSymbol.check,
                                  size: 15,
                                  stroke: 2.5,
                                  color: colors.onAction,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

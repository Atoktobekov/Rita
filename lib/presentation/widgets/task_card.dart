import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../theme/palette.dart';
import 'design_icon.dart';
import 'reference_widgets.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onCopyToToday,
    this.compact = false,
  });

  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopyToToday;
  final bool compact;

  Future<void> _showActions(BuildContext context) async {
    final action = await showDesignSheet<String>(
      context,
      builder: (context) {
        final c = AppPalette.of(context);
        return DesignSheet(
          title: 'Задача',
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Text(
                task.title,
                style: designText(13, height: 1.6, color: c.muted),
              ),
            ),
            SheetAction(
              key: const ValueKey('task-edit'),
              icon: DesignSymbol.edit,
              label: 'Редактировать',
              trailing: DesignIcon(
                DesignSymbol.chevron,
                size: 17,
                color: c.muted,
              ),
              onTap: onEdit == null
                  ? null
                  : () => Navigator.pop(context, 'edit'),
            ),
            if (onCopyToToday != null)
              SheetAction(
                icon: DesignSymbol.copy,
                label: 'Скопировать на сегодня',
                onTap: () => Navigator.pop(context, 'copy'),
              ),
            SheetAction(
              key: const ValueKey('task-delete'),
              icon: DesignSymbol.trash,
              label: 'Удалить',
              danger: true,
              onTap: onDelete == null
                  ? null
                  : () => Navigator.pop(context, 'delete'),
            ),
          ],
        );
      },
    );
    if (!context.mounted) return;
    if (action == 'edit') onEdit?.call();
    if (action == 'copy') onCopyToToday?.call();
    if (action == 'delete') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    final actions = onEdit != null || onDelete != null
        ? () => _showActions(context)
        : null;
    final completed = c.strict
        ? c.ink
        : c.playful
        ? const Color(0xFFA995CD)
        : c.muted.withValues(alpha: .7);
    final checkSize = c.lined ? 21.0 : 23.0;
    final radius = BorderRadius.circular(c.lined ? 0 : c.radius);
    return Semantics(
      label: task.title,
      hint: 'Нажмите, чтобы изменить выполнение. Удерживайте для действий.',
      checked: task.done,
      enabled: onToggle != null,
      onTap: onToggle,
      onLongPress: actions,
      excludeSemantics: true,
      child: AnimatedContainer(
        key: ValueKey(c.design),
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: c.lined
              ? Colors.transparent
              : task.done
              ? c.done
              : c.card,
          borderRadius: c.lined ? null : radius,
          border: c.lined
              ? Border(
                  bottom: BorderSide(
                    color: task.done ? Colors.transparent : c.line,
                  ),
                )
              : Border.all(
                  color: task.done && !c.playful ? Colors.transparent : c.line,
                ),
          boxShadow: c.playful && !task.done
              ? [BoxShadow(color: c.line, offset: const Offset(0, 3))]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey('task-card-${task.id}'),
            onTap: onToggle,
            onLongPress: actions,
            borderRadius: radius,
            child: Container(
              constraints: BoxConstraints(
                minHeight: c.strict
                    ? 57
                    : c.editorial
                    ? 55
                    : compact
                    ? 53
                    : 50,
              ),
              padding: EdgeInsets.fromLTRB(
                c.editorial
                    ? 1
                    : c.strict || compact
                    ? 12
                    : 14,
                0,
                c.editorial
                    ? 3
                    : c.strict || compact
                    ? 12
                    : 14,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: c.strict
                            ? 15
                            : compact || c.playful
                            ? 12
                            : 13,
                      ),
                      child: Text(
                        task.title,
                        style:
                            designText(
                              compact ? 12 : 14,
                              height: 1.55,
                              color: task.done ? c.muted : c.ink,
                            ).copyWith(
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationThickness: 1,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    color: Colors.transparent,
                    key: ValueKey('check-${task.id}'),
                    width: 48,
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: checkSize,
                        height: checkSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.done ? completed : Colors.transparent,
                          border: task.done
                              ? null
                              : Border.all(
                                  color: c.muted.withValues(alpha: .45),
                                  width: 1.4,
                                ),
                        ),
                        child: task.done
                            ? DesignIcon(
                                DesignSymbol.check,
                                size: 13,
                                stroke: 2,
                                color: c.playful ? Colors.white : c.paper,
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

import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../theme/palette.dart';
import 'design_icon.dart';

class TaskCheck extends StatelessWidget {
  const TaskCheck({super.key, required this.done, this.onTap, this.size = 28});
  final bool done;
  final VoidCallback? onTap;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Выполнено',
    checked: done,
    enabled: onTap != null,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? peach : Colors.transparent,
          border: Border.all(color: done ? peach : inkOpacity(.25), width: 2),
        ),
        child: done
            ? Center(
                child: DesignIcon(
                  DesignSymbol.check,
                  size: size * 4 / 7,
                  stroke: 3,
                ),
              )
            : null,
      ),
    ),
  );
}

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
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: inkOpacity(.05)),
      boxShadow: const [
        BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1)),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        TaskCheck(
          key: ValueKey('check-${task.id}'),
          done: task.done,
          onTap: onToggle,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEdit,
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: task.done ? inkOpacity(.35) : ink,
                decoration: task.done ? TextDecoration.lineThrough : null,
                decorationColor: inkOpacity(.35),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'Удалить',
          child: Semantics(
            button: true,
            label: 'Удалить ${task.title}',
            child: GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: DesignIcon(
                DesignSymbol.trash,
                size: 18,
                color: inkOpacity(.25),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

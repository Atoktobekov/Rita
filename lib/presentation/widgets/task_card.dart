import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../theme/palette.dart';
import 'design_icon.dart';

class TaskCheck extends StatelessWidget {
  const TaskCheck({
    super.key,
    required this.done,
    this.onTap,
    this.size = 28,
    this.title = 'Задача',
  });
  final bool done;
  final VoidCallback? onTap;
  final double size;
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    label: title,
    checked: done,
    enabled: onTap != null,
    child: IconButton(
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.zero,
      icon: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? ink : Colors.transparent,
            border: Border.all(color: done ? ink : inkOpacity(.5), width: 2),
          ),
          child: done
              ? Center(
                  child: DesignIcon(
                    DesignSymbol.check,
                    size: size * 4 / 7,
                    stroke: 3,
                    color: cream,
                  ),
                )
              : null,
        ),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Row(
      children: [
        TaskCheck(
          key: ValueKey('check-${task.id}'),
          title: task.title,
          done: task.done,
          onTap: onToggle,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Редактировать ${task.title}, ${task.category}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: task.done ? inkOpacity(.65) : ink,
                          decoration: task.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.category,
                        style: TextStyle(fontSize: 12, color: inkOpacity(.7)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          label: 'Удалить ${task.title}',
          child: IconButton(
            onPressed: onDelete,
            tooltip: 'Удалить',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: DesignIcon(
              DesignSymbol.trash,
              size: 21,
              color: inkOpacity(.65),
            ),
          ),
        ),
      ],
    ),
  );
}

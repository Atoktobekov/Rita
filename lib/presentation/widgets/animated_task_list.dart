import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import 'task_card.dart';
import '../theme/palette.dart';

/// Stable unfinished/completed groups with a position animation. Natural row
/// heights are measured after layout, so wrapping and system text sizes work.
class AnimatedTaskList extends StatefulWidget {
  const AnimatedTaskList({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.busy = false,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final bool busy;

  @override
  State<AnimatedTaskList> createState() => _AnimatedTaskListState();
}

class _AnimatedTaskListState extends State<AnimatedTaskList>
    with SingleTickerProviderStateMixin {
  final _keys = <String, GlobalKey>{};
  Map<String, Offset> _offsets = {};
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    value: 1,
  );
  int _generation = 0;

  List<Task> get _ordered => [
    ...widget.tasks.where((t) => !t.done),
    ...widget.tasks.where((t) => t.done),
  ];

  Map<String, Offset> _positions() => {
    for (final entry in _keys.entries)
      if (entry.value.currentContext?.findRenderObject()
          case final RenderBox box)
        if (box.hasSize)
          entry.key: box.localToGlobal(
            Offset.zero,
            ancestor: context.findRenderObject(),
          ),
  };

  @override
  void didUpdateWidget(AnimatedTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = [
      ...oldWidget.tasks.where((t) => !t.done),
      ...oldWidget.tasks.where((t) => t.done),
    ].map((t) => t.id).toList();
    final after = _ordered.map((t) => t.id).toList();
    if (before.length == after.length &&
        List.generate(
          before.length,
          (i) => before[i] == after[i],
        ).every((v) => v)) {
      return;
    }
    final oldPositions = _positions();
    final generation = ++_generation;
    _animation.stop();
    _offsets = {};
    final remaining = after.toSet();
    _keys.removeWhere((id, _) => !remaining.contains(id));
    if (MediaQuery.disableAnimationsOf(context)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      final newPositions = _positions();
      setState(() {
        _offsets = {
          for (final entry in newPositions.entries)
            if (oldPositions.containsKey(entry.key))
              entry.key: oldPositions[entry.key]! - entry.value,
        };
      });
      _animation.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final task in _ordered)
        AnimatedBuilder(
          key: ValueKey(task.id),
          animation: _animation,
          builder: (context, child) => Transform.translate(
            offset:
                (_offsets[task.id] ?? Offset.zero) *
                (1 - Curves.easeInOutCubic.transform(_animation.value)),
            child: child,
          ),
          child: Padding(
            key: _keys.putIfAbsent(task.id, GlobalKey.new),
            padding: EdgeInsets.only(bottom: AppPalette.of(context).taskGap),
            child: TaskCard(
              task: task,
              onToggle: widget.busy ? null : () => widget.onToggle(task),
              onEdit: widget.busy ? null : () => widget.onEdit(task),
              onDelete: widget.busy ? null : () => widget.onDelete(task),
            ),
          ),
        ),
    ],
  );
}

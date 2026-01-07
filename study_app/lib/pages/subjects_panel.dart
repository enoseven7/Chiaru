import 'package:flutter/material.dart';
import '../models/subject.dart';


class SubjectsPanel extends StatelessWidget {
  final List<Subject> subjects;
  final int selectedIndex;
  final Function(int) onSelect;
  final VoidCallback addSubject;
  final ValueChanged<Subject>? onDelete;

  const SubjectsPanel({
    super.key,
    required this.subjects,
    required this.selectedIndex,
    required this.onSelect,
    required this.addSubject,
    this.onDelete,
  });

  Future<void> _showContextMenu(BuildContext context, Offset position, Subject subject) async {
    if (onDelete == null) return;
    final selection = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: const [
        PopupMenuItem(value: "delete", child: Text("Delete")),
      ],
    );
    if (selection == "delete") {
      onDelete!(subject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 12, top: 15),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Text(
                "Subjects",
                style: textTheme.labelLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 20),
                tooltip: "Add subject",
                onPressed: addSubject,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 12, bottom: 14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              separatorBuilder: (context, _) => const SizedBox(height: 6),
              itemCount: subjects.length,
              itemBuilder: (context, i) {
                final subject = subjects[i];
                final selected = i == selectedIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? colors.primary.withValues(alpha: 0.35)
                          : colors.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onSecondaryTapDown: (details) =>
                        _showContextMenu(context, details.globalPosition, subject),
                    child: ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -1),
                      leading: Icon(
                        Icons.book_outlined,
                        size: 18,
                        color: selected ? colors.primary : colors.onSurfaceVariant,
                      ),
                      title: Text(
                        subject.name,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? colors.primary : colors.onSurface,
                          letterSpacing: 0.1,
                        ),
                      ),
                      onTap: () => onSelect(i),
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }
}

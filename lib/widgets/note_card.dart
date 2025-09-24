import 'package:flutter/material.dart';
import '../models/note.dart';
import '../utils/constants.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                children: [
                  // Completion checkbox
                  Checkbox(
                    value: note.isCompleted,
                    onChanged: onToggleComplete != null
                        ? (value) => onToggleComplete?.call()
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: UIConstants.paddingSmall),

                  // Title and priority
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.displayTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                decoration: note.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: note.isCompleted
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color
                                    : null,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note.priority != NotePriority.medium) ...[
                          const SizedBox(height: 2),
                          _buildPriorityChip(context),
                        ],
                      ],
                    ),
                  ),

                  // Action buttons
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              note.isCompleted
                                  ? Icons.radio_button_unchecked
                                  : Icons.check_circle_outline,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              note.isCompleted
                                  ? 'Mark as Pending'
                                  : 'Mark as Completed',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Content preview
              if (note.hasContent) ...[
                const SizedBox(height: UIConstants.paddingSmall),
                Text(
                  note.shortContent,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: note.isCompleted
                        ? Theme.of(context).textTheme.bodySmall?.color
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Tags
              if (note.hasTags) ...[
                const SizedBox(height: UIConstants.paddingMedium),
                Wrap(
                  spacing: UIConstants.paddingSmall,
                  runSpacing: UIConstants.paddingXSmall,
                  children: note.tags
                      .map((tag) => _buildTagChip(context, tag))
                      .toList(),
                ),
              ],

              // Footer with metadata
              const SizedBox(height: UIConstants.paddingMedium),
              Row(
                children: [
                  // Category
                  if (note.category != null) ...[
                    Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      note.category!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: UIConstants.paddingMedium),
                  ],

                  // Updated date
                  Expanded(
                    child: Text(
                      _formatDateTime(note.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context) {
    Color chipColor;
    switch (note.priority) {
      case NotePriority.urgent:
        chipColor = Colors.red;
        break;
      case NotePriority.high:
        chipColor = Colors.orange;
        break;
      case NotePriority.medium:
        chipColor = Colors.blue;
        break;
      case NotePriority.low:
        chipColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        note.priority.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: chipColor.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'toggle':
        onToggleComplete?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}

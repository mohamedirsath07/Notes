import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../utils/constants.dart';
import 'add_note_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Note Details'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
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
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.isCompleted ? 'Mark as Pending' : 'Mark as Completed',
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and completion status
          Row(
            children: [
              Consumer<NotesProvider>(
                builder: (context, notesProvider, child) {
                  final currentNote =
                      notesProvider.getNoteById(note.id!) ?? note;
                  return Checkbox(
                    value: currentNote.isCompleted,
                    onChanged: (value) => _toggleCompletion(context),
                  );
                },
              ),
              const SizedBox(width: UIConstants.paddingSmall),
              Expanded(
                child: Consumer<NotesProvider>(
                  builder: (context, notesProvider, child) {
                    final currentNote =
                        notesProvider.getNoteById(note.id!) ?? note;
                    return Text(
                      currentNote.displayTitle,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            decoration: currentNote.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: currentNote.isCompleted
                                ? Theme.of(context).textTheme.bodySmall?.color
                                : null,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: UIConstants.paddingLarge),

          // Priority badge
          if (note.priority != NotePriority.medium) ...[
            _buildPriorityBadge(context),
            const SizedBox(height: UIConstants.paddingMedium),
          ],

          // Category
          if (note.category != null) ...[
            _buildInfoRow(
              context,
              icon: Icons.folder_outlined,
              label: 'Category',
              value: note.category!,
            ),
            const SizedBox(height: UIConstants.paddingMedium),
          ],

          // Tags
          if (note.hasTags) ...[
            _buildTagsSection(context),
            const SizedBox(height: UIConstants.paddingLarge),
          ],

          // Content
          _buildContentSection(context),

          const SizedBox(height: UIConstants.paddingLarge),

          // Metadata
          _buildMetadataSection(context),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToEdit(context),
      tooltip: 'Edit Note',
      child: const Icon(Icons.edit),
    );
  }

  Widget _buildPriorityBadge(BuildContext context) {
    Color badgeColor;
    IconData badgeIcon;

    switch (note.priority) {
      case NotePriority.urgent:
        badgeColor = Colors.red;
        badgeIcon = Icons.priority_high;
        break;
      case NotePriority.high:
        badgeColor = Colors.orange;
        badgeIcon = Icons.keyboard_arrow_up;
        break;
      case NotePriority.medium:
        badgeColor = Colors.blue;
        badgeIcon = Icons.remove;
        break;
      case NotePriority.low:
        badgeColor = Colors.green;
        badgeIcon = Icons.keyboard_arrow_down;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingMedium,
        vertical: UIConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            '${note.priority.displayName} Priority',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: UIConstants.paddingSmall),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.label_outline,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: UIConstants.paddingSmall),
            Text(
              'Tags',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.paddingSmall),
        Wrap(
          spacing: UIConstants.paddingSmall,
          runSpacing: UIConstants.paddingXSmall,
          children: note.tags.map((tag) {
            return Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notes,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: UIConstants.paddingSmall),
            Text(
              'Content',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(
            note.content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            icon: Icons.access_time,
            label: 'Created',
            value: _formatDateTime(note.createdAt),
          ),
          const SizedBox(height: UIConstants.paddingSmall),
          _buildInfoRow(
            context,
            icon: Icons.update,
            label: 'Updated',
            value: _formatDateTime(note.updatedAt),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _navigateToEdit(context);
        break;
      case 'toggle':
        _toggleCompletion(context);
        break;
      case 'delete':
        _deleteNote(context);
        break;
    }
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddNoteScreen(noteToEdit: note)),
    );
  }

  void _toggleCompletion(BuildContext context) {
    if (note.id != null) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      notesProvider.toggleNoteCompletion(note.id!);
    }
  }

  void _deleteNote(BuildContext context) {
    if (note.id == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final notesProvider = Provider.of<NotesProvider>(
                context,
                listen: false,
              );
              final success = await notesProvider.deleteNote(note.id!);

              if (success) {
                Navigator.of(context).pop(); // Return to notes list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      notesProvider.errorMessage ?? 'Failed to delete note',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

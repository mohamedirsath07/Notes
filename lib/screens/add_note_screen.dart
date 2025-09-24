import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? noteToEdit;

  const AddNoteScreen({super.key, this.noteToEdit});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagController = TextEditingController();

  NotePriority _selectedPriority = NotePriority.medium;
  List<String> _tags = [];
  bool _isLoading = false;

  bool get _isEditing => widget.noteToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (_isEditing) {
      final note = widget.noteToEdit!;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _categoryController.text = note.category ?? '';
      _selectedPriority = note.priority;
      _tags = List.from(note.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isEditing ? 'Edit Note' : 'Add Note'),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _saveNote,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter note title',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.next,
              validator: _validateTitle,
            ),

            const SizedBox(height: UIConstants.paddingLarge),

            // Content field
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content *',
                hintText: 'Write your note content here',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              textInputAction: TextInputAction.newline,
              maxLines: 10,
              validator: _validateContent,
            ),

            const SizedBox(height: UIConstants.paddingLarge),

            // Category field
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Work, Personal, Ideas',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: UIConstants.paddingLarge),

            // Priority selection
            _buildPrioritySection(),

            const SizedBox(height: UIConstants.paddingLarge),

            // Tags section
            _buildTagsSection(),

            const SizedBox(height: UIConstants.paddingXLarge),

            // Save button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveNote,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? 'Update Note' : 'Create Note'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: UIConstants.paddingMedium,
                ),
              ),
            ),

            // Delete button (only for editing)
            if (_isEditing) ...[
              const SizedBox(height: UIConstants.paddingMedium),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _deleteNote,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Delete Note',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: UIConstants.paddingMedium,
                  ),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: UIConstants.paddingSmall),
        Wrap(
          spacing: UIConstants.paddingSmall,
          children: NotePriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return FilterChip(
              label: Text(priority.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedPriority = priority;
                });
              },
              backgroundColor: isSelected ? null : Colors.grey.shade100,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: UIConstants.paddingSmall),

        // Add tag field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: 'Add a tag',
                  prefixIcon: Icon(Icons.label_outline),
                  isDense: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: UIConstants.paddingSmall),
            IconButton(onPressed: _addTag, icon: const Icon(Icons.add)),
          ],
        ),

        const SizedBox(height: UIConstants.paddingSmall),

        // Display tags
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: UIConstants.paddingSmall,
            runSpacing: UIConstants.paddingXSmall,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ] else ...[
          Text('No tags added', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  // Validation methods
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length > ValidationConstants.noteTitleMaxLength) {
      return 'Title must be less than ${ValidationConstants.noteTitleMaxLength} characters';
    }
    return null;
  }

  String? _validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Content is required';
    }
    if (value.trim().length > ValidationConstants.noteContentMaxLength) {
      return 'Content must be less than ${ValidationConstants.noteContentMaxLength} characters';
    }
    return null;
  }

  // Tag management
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;

    if (tag.length > ValidationConstants.tagMaxLength) {
      _showSnackBar(
        'Tag must be less than ${ValidationConstants.tagMaxLength} characters',
      );
      return;
    }

    if (_tags.length >= ValidationConstants.maxTagsPerNote) {
      _showSnackBar(
        'Maximum ${ValidationConstants.maxTagsPerNote} tags allowed',
      );
      return;
    }

    if (_tags.contains(tag)) {
      _showSnackBar('Tag already exists');
      return;
    }

    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // Save note
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);

      final note = _isEditing
          ? widget.noteToEdit!.copyWith(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              category: _categoryController.text.trim().isEmpty
                  ? null
                  : _categoryController.text.trim(),
              priority: _selectedPriority,
              tags: _tags,
            )
          : Note.create(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              userId: authProvider.userId,
              category: _categoryController.text.trim().isEmpty
                  ? null
                  : _categoryController.text.trim(),
              priority: _selectedPriority,
              tags: _tags,
            );

      final result = _isEditing
          ? await notesProvider.updateNote(widget.noteToEdit!.id!, note)
          : await notesProvider.createNote(note);

      if (result != null) {
        _showSnackBar(
          _isEditing
              ? 'Note updated successfully'
              : 'Note created successfully',
        );
        Navigator.of(context).pop();
      } else {
        _showSnackBar(notesProvider.errorMessage ?? 'Failed to save note');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Delete note
  Future<void> _deleteNote() async {
    if (!_isEditing) return;

    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      final success = await notesProvider.deleteNote(widget.noteToEdit!.id!);

      if (success) {
        _showSnackBar('Note deleted successfully');
        Navigator.of(context).pop();
      } else {
        _showSnackBar(notesProvider.errorMessage ?? 'Failed to delete note');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper methods
  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Note'),
            content: const Text(
              'Are you sure you want to delete this note? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

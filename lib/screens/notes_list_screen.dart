import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../providers/auth_provider.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../utils/constants.dart';
import 'add_note_screen.dart';
import 'note_detail_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _setupScrollListener();
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      if (notesProvider.state == NotesState.initial) {
        notesProvider.initialize();
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final notesProvider = Provider.of<NotesProvider>(
          context,
          listen: false,
        );
        if (notesProvider.canLoadMore) {
          notesProvider.loadMoreNotes();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('My Notes'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return PopupMenuButton<String>(
              onSelected: _handleMenuSelection,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sort',
                  child: Row(
                    children: [
                      Icon(Icons.sort),
                      SizedBox(width: 8),
                      Text('Sort'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        if (notesProvider.state == NotesState.loading &&
            notesProvider.isEmpty) {
          return const LoadingWidget(message: 'Loading notes...');
        }

        if (notesProvider.state == NotesState.error && notesProvider.isEmpty) {
          return ErrorStateWidget(
            message: notesProvider.errorMessage ?? 'Failed to load notes',
            onRetry: () => notesProvider.loadNotes(refresh: true),
          );
        }

        if (notesProvider.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.note_add,
            title: 'No Notes Yet',
            subtitle: 'Create your first note to get started',
            actionText: 'Create Note',
            onAction: () => _navigateToAddNote(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => notesProvider.refreshNotes(),
          child: Column(
            children: [
              _buildFiltersSection(notesProvider),
              Expanded(child: _buildNotesList(notesProvider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection(NotesProvider notesProvider) {
    final hasActiveFilters =
        notesProvider.searchQuery.isNotEmpty ||
        notesProvider.selectedCategory != null ||
        notesProvider.selectedTags.isNotEmpty ||
        notesProvider.selectedPriority != null ||
        notesProvider.isCompletedFilter != null;

    if (!hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Filters:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: () => notesProvider.clearAllFilters(),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.paddingSmall),
          Wrap(
            spacing: UIConstants.paddingSmall,
            runSpacing: UIConstants.paddingXSmall,
            children: _buildActiveFilterChips(notesProvider),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActiveFilterChips(NotesProvider notesProvider) {
    final chips = <Widget>[];

    // Search filter
    if (notesProvider.searchQuery.isNotEmpty) {
      chips.add(
        FilterChipWidget(
          label: 'Search: ${notesProvider.searchQuery}',
          onDeleted: () => notesProvider.clearSearch(),
        ),
      );
    }

    // Category filter
    if (notesProvider.selectedCategory != null) {
      chips.add(
        FilterChipWidget(
          label: 'Category: ${notesProvider.selectedCategory}',
          onDeleted: () => notesProvider.filterByCategory(null),
        ),
      );
    }

    // Priority filter
    if (notesProvider.selectedPriority != null) {
      chips.add(
        FilterChipWidget(
          label: 'Priority: ${notesProvider.selectedPriority!.displayName}',
          onDeleted: () => notesProvider.filterByPriority(null),
        ),
      );
    }

    // Completion filter
    if (notesProvider.isCompletedFilter != null) {
      chips.add(
        FilterChipWidget(
          label: notesProvider.isCompletedFilter! ? 'Completed' : 'Pending',
          onDeleted: () => notesProvider.filterByCompletion(null),
        ),
      );
    }

    // Tags filter
    for (final tag in notesProvider.selectedTags) {
      chips.add(
        FilterChipWidget(
          label: 'Tag: $tag',
          onDeleted: () {
            final newTags = List<String>.from(notesProvider.selectedTags);
            newTags.remove(tag);
            notesProvider.filterByTags(newTags);
          },
        ),
      );
    }

    return chips;
  }

  Widget _buildNotesList(NotesProvider notesProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      itemCount:
          notesProvider.notes.length + (notesProvider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notesProvider.notes.length) {
          return const Padding(
            padding: EdgeInsets.all(UIConstants.paddingMedium),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final note = notesProvider.notes[index];
        return NoteCard(
          note: note,
          onTap: () => _navigateToNoteDetail(note),
          onToggleComplete: () => _toggleNoteCompletion(note),
          onEdit: () => _navigateToEditNote(note),
          onDelete: () => _deleteNote(note),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _navigateToAddNote,
      tooltip: 'Add Note',
      child: const Icon(Icons.add),
    );
  }

  // Navigation methods
  void _navigateToAddNote() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddNoteScreen()));
  }

  void _navigateToEditNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddNoteScreen(noteToEdit: note)),
    );
  }

  void _navigateToNoteDetail(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
    );
  }

  // Action methods
  void _toggleNoteCompletion(Note note) {
    if (note.id != null) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      notesProvider.toggleNoteCompletion(note.id!);
    }
  }

  void _deleteNote(Note note) {
    if (note.id == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              final notesProvider = Provider.of<NotesProvider>(
                context,
                listen: false,
              );
              notesProvider.deleteNote(note.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchBarWidget(
        controller: _searchController,
        onSearch: (query) {
          final notesProvider = Provider.of<NotesProvider>(
            context,
            listen: false,
          );
          notesProvider.searchNotes(query);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showFilterDialog() {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(notesProvider: notesProvider),
    );
  }

  void _showSortDialog() {
    showDialog(context: context, builder: (context) => _SortDialog());
  }

  void _handleMenuSelection(String value) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (value) {
      case 'refresh':
        notesProvider.refreshNotes();
        break;
      case 'sort':
        _showSortDialog();
        break;
      case 'profile':
        // Navigate to profile screen
        break;
      case 'logout':
        _showLogoutDialog(authProvider);
        break;
    }
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final NotesProvider notesProvider;

  const _FilterBottomSheet({required this.notesProvider});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _selectedCategory;
  List<String> _selectedTags = [];
  NotePriority? _selectedPriority;
  bool? _isCompletedFilter;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.notesProvider.selectedCategory;
    _selectedTags = List.from(widget.notesProvider.selectedTags);
    _selectedPriority = widget.notesProvider.selectedPriority;
    _isCompletedFilter = widget.notesProvider.isCompletedFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filter Notes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: UIConstants.paddingLarge),

          // Category filter
          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: UIConstants.paddingSmall),
          Wrap(
            spacing: UIConstants.paddingSmall,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = null);
                  }
                },
              ),
              ...widget.notesProvider.categories.map(
                (category) => FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: UIConstants.paddingLarge),

          // Priority filter
          Text('Priority', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: UIConstants.paddingSmall),
          Wrap(
            spacing: UIConstants.paddingSmall,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedPriority == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPriority = null);
                  }
                },
              ),
              ...NotePriority.values.map(
                (priority) => FilterChip(
                  label: Text(priority.displayName),
                  selected: _selectedPriority == priority,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPriority = selected ? priority : null;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: UIConstants.paddingLarge),

          // Status filter
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: UIConstants.paddingSmall),
          Wrap(
            spacing: UIConstants.paddingSmall,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _isCompletedFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _isCompletedFilter = null);
                  }
                },
              ),
              FilterChip(
                label: const Text('Completed'),
                selected: _isCompletedFilter == true,
                onSelected: (selected) {
                  setState(() {
                    _isCompletedFilter = selected ? true : null;
                  });
                },
              ),
              FilterChip(
                label: const Text('Pending'),
                selected: _isCompletedFilter == false,
                onSelected: (selected) {
                  setState(() {
                    _isCompletedFilter = selected ? false : null;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: UIConstants.paddingXLarge),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: UIConstants.paddingMedium),
              Expanded(
                child: FilledButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    widget.notesProvider.filterByCategory(_selectedCategory);
    widget.notesProvider.filterByTags(_selectedTags);
    widget.notesProvider.filterByPriority(_selectedPriority);
    widget.notesProvider.filterByCompletion(_isCompletedFilter);
    Navigator.of(context).pop();
  }
}

// Sort Dialog Widget
class _SortDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        return AlertDialog(
          title: const Text('Sort Notes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date Created (Newest)'),
                leading: Radio<String>(
                  value: 'created_at:desc',
                  groupValue:
                      '${notesProvider.sortBy}:${notesProvider.sortOrder}',
                  onChanged: (value) =>
                      _applySorting(context, 'created_at', 'desc'),
                ),
              ),
              ListTile(
                title: const Text('Date Created (Oldest)'),
                leading: Radio<String>(
                  value: 'created_at:asc',
                  groupValue:
                      '${notesProvider.sortBy}:${notesProvider.sortOrder}',
                  onChanged: (value) =>
                      _applySorting(context, 'created_at', 'asc'),
                ),
              ),
              ListTile(
                title: const Text('Date Updated (Newest)'),
                leading: Radio<String>(
                  value: 'updated_at:desc',
                  groupValue:
                      '${notesProvider.sortBy}:${notesProvider.sortOrder}',
                  onChanged: (value) =>
                      _applySorting(context, 'updated_at', 'desc'),
                ),
              ),
              ListTile(
                title: const Text('Date Updated (Oldest)'),
                leading: Radio<String>(
                  value: 'updated_at:asc',
                  groupValue:
                      '${notesProvider.sortBy}:${notesProvider.sortOrder}',
                  onChanged: (value) =>
                      _applySorting(context, 'updated_at', 'asc'),
                ),
              ),
              ListTile(
                title: const Text('Title (A-Z)'),
                leading: Radio<String>(
                  value: 'title:asc',
                  groupValue:
                      '${notesProvider.sortBy}:${notesProvider.sortOrder}',
                  onChanged: (value) => _applySorting(context, 'title', 'asc'),
                ),
              ),
              ListTile(
                title: const Text('Title (Z-A)'),
                leading: Radio<String>(
                  value: 'title:desc',
                  groupValue:
                      '${notesProvider.sortBy}:${notesProvider.sortOrder}',
                  onChanged: (value) => _applySorting(context, 'title', 'desc'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _applySorting(BuildContext context, String sortBy, String sortOrder) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    notesProvider.changeSorting(sortBy, sortOrder);
    Navigator.of(context).pop();
  }
}

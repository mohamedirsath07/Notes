import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/api_response.dart';
import '../services/notes_service.dart';
import '../utils/constants.dart';

enum NotesState { initial, loading, loaded, error, refreshing, loadingMore }

class NotesProvider extends ChangeNotifier {
  final NotesService _notesService = NotesService();

  // State
  NotesState _state = NotesState.initial;
  List<Note> _notes = [];
  String? _errorMessage;
  List<String> _errorDetails = [];

  // Pagination
  int _currentPage = 1;
  int _pageSize = DefaultValues.defaultPageSize;
  int _totalCount = 0;
  int _totalPages = 0;
  bool _hasNext = false;
  bool _hasPrevious = false;

  // Filtering and search
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _selectedTags = [];
  NotePriority? _selectedPriority;
  bool? _isCompletedFilter;
  String _sortBy = DefaultValues.defaultSortBy;
  String _sortOrder = DefaultValues.defaultSortOrder;

  // Cache and metadata
  DateTime? _lastSyncTime;
  bool _isOfflineMode = false;

  // Available options
  List<String> _categories = [];
  List<String> _tags = [];
  Map<String, int> _statistics = {};

  // Getters
  NotesState get state => _state;
  List<Note> get notes => _notes;
  String? get errorMessage => _errorMessage;
  List<String> get errorDetails => _errorDetails;

  // Pagination getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  bool get hasNext => _hasNext;
  bool get hasPrevious => _hasPrevious;
  bool get hasNotes => _notes.isNotEmpty;
  bool get isEmpty => _notes.isEmpty && _state == NotesState.loaded;

  // Filter getters
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  List<String> get selectedTags => _selectedTags;
  NotePriority? get selectedPriority => _selectedPriority;
  bool? get isCompletedFilter => _isCompletedFilter;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  // Metadata getters
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isOfflineMode => _isOfflineMode;
  List<String> get categories => _categories;
  List<String> get tags => _tags;
  Map<String, int> get statistics => _statistics;

  // Status getters
  bool get isLoading => _state == NotesState.loading;
  bool get isRefreshing => _state == NotesState.refreshing;
  bool get isLoadingMore => _state == NotesState.loadingMore;
  bool get hasError => _state == NotesState.error;
  bool get canLoadMore => _hasNext && !isLoading && !isLoadingMore;

  // Initialize provider
  Future<void> initialize() async {
    await loadNotes();
    await loadMetadata();
  }

  // Load notes with current filters
  Future<void> loadNotes({bool refresh = false}) async {
    if (refresh) {
      _setState(NotesState.refreshing);
      _currentPage = 1;
      _notes.clear();
    } else if (_notes.isEmpty) {
      _setState(NotesState.loading);
    }

    try {
      final response = await _notesService.getNotes(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        priority: _selectedPriority,
        isCompleted: _isCompletedFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (response.success && response.data != null) {
        final paginatedData = response.data!;

        if (refresh || _currentPage == 1) {
          _notes = paginatedData.items;
        } else {
          _notes.addAll(paginatedData.items);
        }

        _updatePaginationInfo(paginatedData);
        _lastSyncTime = DateTime.now();
        _setState(NotesState.loaded);
      } else {
        _setError(response.message, response.errors);
      }
    } catch (e) {
      _setError('Failed to load notes', [e.toString()]);
    }
  }

  // Load more notes (pagination)
  Future<void> loadMoreNotes() async {
    if (!canLoadMore) return;

    _setState(NotesState.loadingMore);
    _currentPage++;

    try {
      final response = await _notesService.getNotes(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        priority: _selectedPriority,
        isCompleted: _isCompletedFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (response.success && response.data != null) {
        final paginatedData = response.data!;
        _notes.addAll(paginatedData.items);
        _updatePaginationInfo(paginatedData);
        _setState(NotesState.loaded);
      } else {
        _currentPage--; // Revert page increment on error
        _setError(response.message, response.errors);
      }
    } catch (e) {
      _currentPage--; // Revert page increment on error
      _setError('Failed to load more notes', [e.toString()]);
    }
  }

  // Refresh notes
  Future<void> refreshNotes() async {
    await loadNotes(refresh: true);
  }

  // Search notes
  Future<void> searchNotes(String query) async {
    if (_searchQuery == query) return;

    _searchQuery = query;
    _currentPage = 1;
    await loadNotes(refresh: true);
  }

  // Clear search
  Future<void> clearSearch() async {
    if (_searchQuery.isEmpty) return;

    _searchQuery = '';
    _currentPage = 1;
    await loadNotes(refresh: true);
  }

  // Filter by category
  Future<void> filterByCategory(String? category) async {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    _currentPage = 1;
    await loadNotes(refresh: true);
  }

  // Filter by tags
  Future<void> filterByTags(List<String> tags) async {
    if (_listEquals(_selectedTags, tags)) return;

    _selectedTags = tags;
    _currentPage = 1;
    await loadNotes(refresh: true);
  }

  // Filter by priority
  Future<void> filterByPriority(NotePriority? priority) async {
    if (_selectedPriority == priority) return;

    _selectedPriority = priority;
    _currentPage = 1;
    await loadNotes(refresh: true);
  }

  // Filter by completion status
  Future<void> filterByCompletion(bool? isCompleted) async {
    if (_isCompletedFilter == isCompleted) return;

    _isCompletedFilter = isCompleted;
    _currentPage = 1;
    await loadNotes(refresh: true);
  }

  // Change sorting
  Future<void> changeSorting(String sortBy, String sortOrder) async {
    if (_sortBy == sortBy && _sortOrder == sortOrder) return;

    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _currentPage = 1;
    await loadNotes(refresh: true);
  }

  // Clear all filters
  Future<void> clearAllFilters() async {
    bool hasFilters =
        _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        _selectedTags.isNotEmpty ||
        _selectedPriority != null ||
        _isCompletedFilter != null;

    if (!hasFilters) return;

    _searchQuery = '';
    _selectedCategory = null;
    _selectedTags = [];
    _selectedPriority = null;
    _isCompletedFilter = null;
    _currentPage = 1;
    await loadNotes(refresh: true);
  }

  // Create a new note
  Future<Note?> createNote(Note note) async {
    try {
      final response = await _notesService.createNote(note);

      if (response.success && response.data != null) {
        final newNote = response.data!;
        _notes.insert(0, newNote); // Add to top of list
        _totalCount++;
        notifyListeners();
        return newNote;
      } else {
        _setError(response.message, response.errors);
        return null;
      }
    } catch (e) {
      _setError('Failed to create note', [e.toString()]);
      return null;
    }
  }

  // Update an existing note
  Future<Note?> updateNote(String noteId, Note updatedNote) async {
    try {
      final response = await _notesService.updateNote(noteId, updatedNote);

      if (response.success && response.data != null) {
        final note = response.data!;
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notes[index] = note;
          notifyListeners();
        }
        return note;
      } else {
        _setError(response.message, response.errors);
        return null;
      }
    } catch (e) {
      _setError('Failed to update note', [e.toString()]);
      return null;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      final response = await _notesService.deleteNote(noteId);

      if (response.success) {
        _notes.removeWhere((note) => note.id == noteId);
        _totalCount--;
        notifyListeners();
        return true;
      } else {
        _setError(response.message, response.errors);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete note', [e.toString()]);
      return false;
    }
  }

  // Toggle note completion
  Future<Note?> toggleNoteCompletion(String noteId) async {
    // Optimistic update
    final noteIndex = _notes.indexWhere((note) => note.id == noteId);
    if (noteIndex == -1) return null;

    final originalNote = _notes[noteIndex];
    final optimisticNote = originalNote.toggleCompletion();
    _notes[noteIndex] = optimisticNote;
    notifyListeners();

    try {
      final response = await _notesService.toggleNoteCompletion(noteId);

      if (response.success && response.data != null) {
        final updatedNote = response.data!;
        _notes[noteIndex] = updatedNote;
        notifyListeners();
        return updatedNote;
      } else {
        // Revert optimistic update on error
        _notes[noteIndex] = originalNote;
        _setError(response.message, response.errors);
        return null;
      }
    } catch (e) {
      // Revert optimistic update on error
      _notes[noteIndex] = originalNote;
      _setError('Failed to update note status', [e.toString()]);
      return null;
    }
  }

  // Load metadata (categories, tags, statistics)
  Future<void> loadMetadata() async {
    try {
      // Load categories
      final categoriesResponse = await _notesService.getCategories();
      if (categoriesResponse.success && categoriesResponse.data != null) {
        _categories = categoriesResponse.data!;
      }

      // Load tags
      final tagsResponse = await _notesService.getTags();
      if (tagsResponse.success && tagsResponse.data != null) {
        _tags = tagsResponse.data!;
      }

      // Load statistics
      final statsResponse = await _notesService.getNotesStatistics();
      if (statsResponse.success && statsResponse.data != null) {
        _statistics = statsResponse.data!;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load metadata: $e');
    }
  }

  // Get a note by ID
  Note? getNoteById(String noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }

  // Get notes by category
  List<Note> getNotesByCategory(String category) {
    return _notes.where((note) => note.category == category).toList();
  }

  // Get completed notes
  List<Note> getCompletedNotes() {
    return _notes.where((note) => note.isCompleted).toList();
  }

  // Get pending notes
  List<Note> getPendingNotes() {
    return _notes.where((note) => !note.isCompleted).toList();
  }

  // Get notes by priority
  List<Note> getNotesByPriority(NotePriority priority) {
    return _notes.where((note) => note.priority == priority).toList();
  }

  // Clear error
  void clearError() {
    if (_state == NotesState.error) {
      _errorMessage = null;
      _errorDetails = [];
      _setState(NotesState.loaded);
    }
  }

  // Private helper methods
  void _setState(NotesState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _setError(String message, List<String>? errors) {
    _errorMessage = message;
    _errorDetails = errors ?? [];
    _setState(NotesState.error);
  }

  void _updatePaginationInfo(PaginatedResponse<Note> paginatedData) {
    _totalCount = paginatedData.totalCount;
    _totalPages = paginatedData.totalPages;
    _hasNext = paginatedData.hasNext;
    _hasPrevious = paginatedData.hasPrevious;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import '../utils/exceptions.dart';
import 'api_service.dart';

class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  final ApiService _apiService = ApiService();
  
  // Mock mode for testing without API
  static const bool _mockMode = true;

  // Get all notes with optional filtering and pagination
  Future<ApiResponse<PaginatedResponse<Note>>> getNotes({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? category,
    List<String>? tags,
    NotePriority? priority,
    bool? isCompleted,
    String sortBy = 'updated_at',
    String sortOrder = 'desc',
  }) async {
    if (_mockMode) {
      // Return mock notes data
      final mockNotes = [
        Note(
          id: '1',
          title: 'Welcome to Notes App',
          content: 'This is your first note! You can edit, delete, and organize your notes here.',
          category: 'Personal',
          priority: NotePriority.medium,
          tags: ['welcome', 'tutorial'],
          isCompleted: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Note(
          id: '2',
          title: 'Shopping List',
          content: 'Milk, Bread, Eggs, Cheese',
          category: 'Personal',
          priority: NotePriority.high,
          tags: ['shopping'],
          isCompleted: false,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];

      final paginatedResponse = PaginatedResponse<Note>(
        items: mockNotes,
        totalCount: mockNotes.length,
        page: page,
        pageSize: pageSize,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      );

      return ApiResponse<PaginatedResponse<Note>>(
        success: true,
        data: paginatedResponse,
        message: 'Notes loaded successfully',
      );
    }

    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      if (category != null && category.isNotEmpty) {
        queryParameters['category'] = category;
      }

      if (tags != null && tags.isNotEmpty) {
        queryParameters['tags'] = tags.join(',');
      }

      if (priority != null) {
        queryParameters['priority'] = priority.name;
      }

      if (isCompleted != null) {
        queryParameters['is_completed'] = isCompleted;
      }

      final response = await _apiService.get<PaginatedResponse<Note>>(
        ApiEndpoints.getNotes,
        queryParameters: queryParameters,
        fromJson: (json) => PaginatedResponse<Note>.fromJson(
          json as Map<String, dynamic>,
          (noteJson) => Note.fromJson(noteJson as Map<String, dynamic>),
        ),
      );

      return response;
    } catch (e) {
      debugPrint('Get notes error: $e');
      return ApiResponse<PaginatedResponse<Note>>.error(
        message: 'Failed to load notes',
        errors: [e.toString()],
      );
    }
  }

  // Get a single note by ID
  Future<ApiResponse<Note>> getNote(String noteId) async {
    if (_mockMode) {
      // Return a mock note based on the ID
      final mockNote = Note(
        id: noteId,
        title: 'Sample Note',
        content: 'This is a sample note content for note with ID: $noteId',
        category: 'Personal',
        priority: NotePriority.medium,
        tags: ['sample'],
        isCompleted: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      return ApiResponse<Note>(
        success: true,
        data: mockNote,
        message: 'Note loaded successfully',
      );
    }

    try {
      final response = await _apiService.get<Note>(
        '${ApiEndpoints.getNote}/$noteId',
        fromJson: (json) => Note.fromJson(json as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      debugPrint('Get note error: $e');
      return ApiResponse<Note>.error(
        message: 'Failed to load note',
        errors: [e.toString()],
      );
    }
  }

  // Create a new note
  Future<ApiResponse<Note>> createNote(Note note) async {
    if (_mockMode) {
      // Validate note before creating
      if (!note.isValid) {
        return ApiResponse<Note>.error(
          message: 'Please provide both title and content for the note',
          errors: ['VALIDATION_ERROR'],
        );
      }

      // Create a mock note with generated ID and timestamps
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: note.title,
        content: note.content,
        category: note.category,
        priority: note.priority,
        tags: note.tags,
        isCompleted: note.isCompleted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return ApiResponse<Note>(
        success: true,
        data: newNote,
        message: 'Note created successfully',
      );
    }

    try {
      // Validate note before sending
      if (!note.isValid) {
        return ApiResponse<Note>.error(
          message: 'Please provide both title and content for the note',
          errors: ['VALIDATION_ERROR'],
        );
      }

      final response = await _apiService.post<Note>(
        ApiEndpoints.createNote,
        data: note.toJson(),
        fromJson: (json) => Note.fromJson(json as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      debugPrint('Create note error: $e');
      return ApiResponse<Note>.error(
        message: 'Failed to create note',
        errors: [e.toString()],
      );
    }
  }

  // Update an existing note
  Future<ApiResponse<Note>> updateNote(String noteId, Note note) async {
    if (_mockMode) {
      // Validate note before updating
      if (!note.isValid) {
        return ApiResponse<Note>.error(
          message: 'Please provide both title and content for the note',
          errors: ['VALIDATION_ERROR'],
        );
      }

      // Create updated note with same ID but new updated timestamp
      final updatedNote = Note(
        id: noteId,
        title: note.title,
        content: note.content,
        category: note.category,
        priority: note.priority,
        tags: note.tags,
        isCompleted: note.isCompleted,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
      );

      return ApiResponse<Note>(
        success: true,
        data: updatedNote,
        message: 'Note updated successfully',
      );
    }

    try {
      // Validate note before sending
      if (!note.isValid) {
        return ApiResponse<Note>.error(
          message: 'Please provide both title and content for the note',
          errors: ['VALIDATION_ERROR'],
        );
      }

      final response = await _apiService.put<Note>(
        '${ApiEndpoints.updateNote}/$noteId',
        data: note.toJson(),
        fromJson: (json) => Note.fromJson(json as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      debugPrint('Update note error: $e');
      return ApiResponse<Note>.error(
        message: 'Failed to update note',
        errors: [e.toString()],
      );
    }
  }

  // Delete a note
  Future<ApiResponse<void>> deleteNote(String noteId) async {
    if (_mockMode) {
      return ApiResponse<void>(
        success: true,
        message: 'Note deleted successfully',
      );
    }

    try {
      final response = await _apiService.delete<void>(
        '${ApiEndpoints.deleteNote}/$noteId',
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message,
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Delete note error: $e');
      return ApiResponse<void>.error(
        message: 'Failed to delete note',
        errors: [e.toString()],
      );
    }
  }

  // Toggle note completion status
  Future<ApiResponse<Note>> toggleNoteCompletion(String noteId) async {
    try {
      final response = await _apiService.put<Note>(
        '${ApiEndpoints.toggleComplete}/$noteId/toggle',
        fromJson: (json) => Note.fromJson(json as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      debugPrint('Toggle note completion error: $e');
      return ApiResponse<Note>.error(
        message: 'Failed to update note status',
        errors: [e.toString()],
      );
    }
  }

  // Search notes
  Future<ApiResponse<PaginatedResponse<Note>>> searchNotes({
    required String query,
    int page = 1,
    int pageSize = 20,
    String? category,
    List<String>? tags,
    NotePriority? priority,
    bool? isCompleted,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'q': query,
        'page': page,
        'page_size': pageSize,
      };

      if (category != null && category.isNotEmpty) {
        queryParameters['category'] = category;
      }

      if (tags != null && tags.isNotEmpty) {
        queryParameters['tags'] = tags.join(',');
      }

      if (priority != null) {
        queryParameters['priority'] = priority.name;
      }

      if (isCompleted != null) {
        queryParameters['is_completed'] = isCompleted;
      }

      final response = await _apiService.get<PaginatedResponse<Note>>(
        ApiEndpoints.searchNotes,
        queryParameters: queryParameters,
        fromJson: (json) => PaginatedResponse<Note>.fromJson(
          json as Map<String, dynamic>,
          (noteJson) => Note.fromJson(noteJson as Map<String, dynamic>),
        ),
      );

      return response;
    } catch (e) {
      debugPrint('Search notes error: $e');
      return ApiResponse<PaginatedResponse<Note>>.error(
        message: 'Failed to search notes',
        errors: [e.toString()],
      );
    }
  }

  // Get notes by category
  Future<ApiResponse<PaginatedResponse<Note>>> getNotesByCategory(
    String category, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getNotes(page: page, pageSize: pageSize, category: category);
  }

  // Get notes by tags
  Future<ApiResponse<PaginatedResponse<Note>>> getNotesByTags(
    List<String> tags, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getNotes(page: page, pageSize: pageSize, tags: tags);
  }

  // Get notes by priority
  Future<ApiResponse<PaginatedResponse<Note>>> getNotesByPriority(
    NotePriority priority, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getNotes(page: page, pageSize: pageSize, priority: priority);
  }

  // Get completed notes
  Future<ApiResponse<PaginatedResponse<Note>>> getCompletedNotes({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getNotes(page: page, pageSize: pageSize, isCompleted: true);
  }

  // Get pending notes
  Future<ApiResponse<PaginatedResponse<Note>>> getPendingNotes({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getNotes(page: page, pageSize: pageSize, isCompleted: false);
  }

  // Get all available categories
  Future<ApiResponse<List<String>>> getCategories() async {
    if (_mockMode) {
      final mockCategories = ['Personal', 'Work', 'Study', 'Health', 'Travel'];
      return ApiResponse<List<String>>(
        success: true,
        data: mockCategories,
        message: 'Categories loaded successfully',
      );
    }

    try {
      final response = await _apiService.get<List<String>>(
        ApiEndpoints.categories,
        fromJson: (json) => List<String>.from(json as List),
      );

      return response;
    } catch (e) {
      debugPrint('Get categories error: $e');
      return ApiResponse<List<String>>.error(
        message: 'Failed to load categories',
        errors: [e.toString()],
      );
    }
  }

  // Get all available tags
  Future<ApiResponse<List<String>>> getTags() async {
    if (_mockMode) {
      final mockTags = ['important', 'todo', 'reminder', 'work', 'personal', 'urgent'];
      return ApiResponse<List<String>>(
        success: true,
        data: mockTags,
        message: 'Tags loaded successfully',
      );
    }

    try {
      final response = await _apiService.get<List<String>>(
        ApiEndpoints.tags,
        fromJson: (json) => List<String>.from(json as List),
      );

      return response;
    } catch (e) {
      debugPrint('Get tags error: $e');
      return ApiResponse<List<String>>.error(
        message: 'Failed to load tags',
        errors: [e.toString()],
      );
    }
  }

  // Bulk operations
  Future<ApiResponse<void>> bulkDeleteNotes(List<String> noteIds) async {
    try {
      final response = await _apiService.delete<void>(
        ApiEndpoints.notes,
        data: {'note_ids': noteIds},
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message,
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Bulk delete notes error: $e');
      return ApiResponse<void>.error(
        message: 'Failed to delete notes',
        errors: [e.toString()],
      );
    }
  }

  // Bulk mark as completed
  Future<ApiResponse<void>> bulkMarkAsCompleted(List<String> noteIds) async {
    try {
      final response = await _apiService.put<void>(
        '${ApiEndpoints.notes}/bulk-complete',
        data: {'note_ids': noteIds, 'is_completed': true},
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message,
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Bulk mark as completed error: $e');
      return ApiResponse<void>.error(
        message: 'Failed to mark notes as completed',
        errors: [e.toString()],
      );
    }
  }

  // Bulk mark as pending
  Future<ApiResponse<void>> bulkMarkAsPending(List<String> noteIds) async {
    try {
      final response = await _apiService.put<void>(
        '${ApiEndpoints.notes}/bulk-complete',
        data: {'note_ids': noteIds, 'is_completed': false},
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message,
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Bulk mark as pending error: $e');
      return ApiResponse<void>.error(
        message: 'Failed to mark notes as pending',
        errors: [e.toString()],
      );
    }
  }

  // Statistics
  Future<ApiResponse<Map<String, int>>> getNotesStatistics() async {
    if (_mockMode) {
      final mockStats = {
        'total': 5,
        'completed': 2,
        'pending': 3,
        'high_priority': 1,
        'medium_priority': 3,
        'low_priority': 1,
      };
      return ApiResponse<Map<String, int>>(
        success: true,
        data: mockStats,
        message: 'Statistics loaded successfully',
      );
    }

    try {
      final response = await _apiService.get<Map<String, int>>(
        '${ApiEndpoints.notes}/statistics',
        fromJson: (json) => Map<String, int>.from(json as Map),
      );

      return response;
    } catch (e) {
      debugPrint('Get notes statistics error: $e');
      return ApiResponse<Map<String, int>>.error(
        message: 'Failed to load statistics',
        errors: [e.toString()],
      );
    }
  }
}

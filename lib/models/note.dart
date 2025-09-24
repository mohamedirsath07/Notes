import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  final String? id;
  final String title;
  final String content;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final List<String> tags;
  final NotePriority priority;
  final String? category;

  const Note({
    this.id,
    required this.title,
    required this.content,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.tags = const [],
    this.priority = NotePriority.medium,
    this.category,
  });

  // Factory constructor for creating a new Note instance from JSON
  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  // Method for converting Note instance to JSON
  Map<String, dynamic> toJson() => _$NoteToJson(this);

  // Create a new note (without ID for creation)
  factory Note.create({
    required String title,
    required String content,
    String? userId,
    List<String> tags = const [],
    NotePriority priority = NotePriority.medium,
    String? category,
  }) {
    final now = DateTime.now();
    return Note(
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      userId: userId,
      tags: tags,
      priority: priority,
      category: category,
    );
  }

  // Copy with method for updating note properties
  Note copyWith({
    String? id,
    String? title,
    String? content,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    List<String>? tags,
    NotePriority? priority,
    String? category,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      category: category ?? this.category,
    );
  }

  // Mark note as completed
  Note markAsCompleted() {
    return copyWith(isCompleted: true);
  }

  // Mark note as incomplete
  Note markAsIncomplete() {
    return copyWith(isCompleted: false);
  }

  // Toggle completion status
  Note toggleCompletion() {
    return copyWith(isCompleted: !isCompleted);
  }

  // Add tag to note
  Note addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  // Remove tag from note
  Note removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  // Validation methods
  bool get isValid => title.trim().isNotEmpty && content.trim().isNotEmpty;

  bool get hasContent => content.trim().isNotEmpty;

  bool get hasTags => tags.isNotEmpty;

  String get displayTitle => title.isEmpty ? 'Untitled Note' : title;

  String get shortContent =>
      content.length > 100 ? '${content.substring(0, 97)}...' : content;

  // Search functionality
  bool containsQuery(String query) {
    final searchQuery = query.toLowerCase();
    return title.toLowerCase().contains(searchQuery) ||
        content.toLowerCase().contains(searchQuery) ||
        tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
        (category?.toLowerCase().contains(searchQuery) ?? false);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ content.hashCode ^ isCompleted.hashCode;

  @override
  String toString() {
    return 'Note{id: $id, title: $title, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}, isCompleted: $isCompleted, createdAt: $createdAt, priority: $priority}';
  }
}

@JsonEnum()
enum NotePriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

extension NotePriorityExtension on NotePriority {
  String get displayName {
    switch (this) {
      case NotePriority.low:
        return 'Low';
      case NotePriority.medium:
        return 'Medium';
      case NotePriority.high:
        return 'High';
      case NotePriority.urgent:
        return 'Urgent';
    }
  }

  int get sortOrder {
    switch (this) {
      case NotePriority.urgent:
        return 4;
      case NotePriority.high:
        return 3;
      case NotePriority.medium:
        return 2;
      case NotePriority.low:
        return 1;
    }
  }
}

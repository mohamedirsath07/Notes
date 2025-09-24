// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
  id: json['id'] as String?,
  title: json['title'] as String,
  content: json['content'] as String,
  isCompleted: json['isCompleted'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  userId: json['userId'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  priority:
      $enumDecodeNullable(_$NotePriorityEnumMap, json['priority']) ??
      NotePriority.medium,
  category: json['category'] as String?,
);

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'isCompleted': instance.isCompleted,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'userId': instance.userId,
  'tags': instance.tags,
  'priority': _$NotePriorityEnumMap[instance.priority]!,
  'category': instance.category,
};

const _$NotePriorityEnumMap = {
  NotePriority.low: 'low',
  NotePriority.medium: 'medium',
  NotePriority.high: 'high',
  NotePriority.urgent: 'urgent',
};

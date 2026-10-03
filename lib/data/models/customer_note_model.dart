import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomerNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory CustomerNote.fromMap(String id, Map<String, dynamic> map) {
    return CustomerNote(
      id: id,
      content: map['content'] ?? '',
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CustomerNote copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerNote(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

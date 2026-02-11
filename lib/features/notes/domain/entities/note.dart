/// Immutable Note entity
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? color;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });

  /// Create a copy with some fields changed
  /// Note: For nullable fields like color, passing null will retain the existing value.
  /// To clear a nullable field, pass an explicit empty string or handle it separately.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.color == color;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      createdAt,
      updatedAt,
      color,
    );
  }
}

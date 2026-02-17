import 'package:hive/hive.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      isPinned: fields[5] as bool,
      type: fields[6] as String,
      language: fields[7] as String?,
      audioPath: fields[8] as String?,
      embedding: (fields[9] as List?)?.cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.isPinned)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.language)
      ..writeByte(8)
      ..write(obj.audioPath)
      ..writeByte(9)
      ..write(obj.embedding);
  }
}

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.title,
    required super.content,
    required super.createdAt,
    required super.updatedAt,
    super.isPinned,
    super.type,
    super.language,
    super.audioPath,
    super.embedding,
  });

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isPinned: note.isPinned,
      type: note.type,
      language: note.language,
      audioPath: note.audioPath,
      embedding: note.embedding,
    );
  }
}
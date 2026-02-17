import 'package:hive_flutter/hive_flutter.dart';
import 'package:second_brain/features/notes/data/models/note_model.dart';
import 'package:second_brain/core/errors/failures.dart';

abstract class NotesLocalDatasource {
  Future<List<NoteModel>> getNotes();
  Future<void> cacheNote(NoteModel note);
  Future<void> deleteNote(String id);
}

class NotesLocalDatasourceImpl implements NotesLocalDatasource {
  final Box<NoteModel> _noteBox;

  NotesLocalDatasourceImpl(this._noteBox);

  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      return _noteBox.values.toList();
    } catch (e) {
      throw const CacheFailure(); // FIXED: const
    }
  }

  @override
  Future<void> cacheNote(NoteModel note) async {
    try {
      await _noteBox.put(note.id, note);
    } catch (e) {
      throw const CacheFailure();
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      await _noteBox.delete(id);
    } catch (e) {
      throw const CacheFailure();
    }
  }
}
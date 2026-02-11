import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:second_brain/features/notes/data/models/note_model.dart';

/// Local data source for notes using SharedPreferences
class NotesLocalDatasource {
  final SharedPreferences sharedPreferences;
  static const String _notesKey = 'notes_list';

  const NotesLocalDatasource(this.sharedPreferences);

  /// Get all notes from SharedPreferences
  Future<List<NoteModel>> getNotes() async {
    try {
      final String? notesJson = sharedPreferences.getString(_notesKey);
      if (notesJson == null || notesJson.isEmpty) {
        return [];
      }

      final List<dynamic> notesList = json.decode(notesJson);
      return notesList
          .map((noteMap) => NoteModel.fromJson(noteMap as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Save notes to SharedPreferences
  Future<void> saveNotes(List<NoteModel> notes) async {
    try {
      final List<Map<String, dynamic>> notesJson =
          notes.map((note) => note.toJson()).toList();
      final String encodedNotes = json.encode(notesJson);
      await sharedPreferences.setString(_notesKey, encodedNotes);
    } catch (e) {
      throw Exception('Failed to save notes: $e');
    }
  }

  /// Delete a note by ID
  Future<void> deleteNote(String id) async {
    try {
      final notes = await getNotes();
      final updatedNotes = notes.where((note) => note.id != id).toList();
      await saveNotes(updatedNotes);
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }
}

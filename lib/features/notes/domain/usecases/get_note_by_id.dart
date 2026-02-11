import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

/// Use case to get a single note by ID
class GetNoteById {
  final NotesRepository repository;

  const GetNoteById(this.repository);

  Future<Note?> call(String id) async {
    return await repository.getNoteById(id);
  }
}

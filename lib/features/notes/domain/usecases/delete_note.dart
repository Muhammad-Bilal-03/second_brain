import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

/// Use case to delete a note by ID
class DeleteNote {
  final NotesRepository repository;

  const DeleteNote(this.repository);

  Future<void> call(String id) async {
    await repository.deleteNote(id);
  }
}

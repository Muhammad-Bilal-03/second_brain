import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:second_brain/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:second_brain/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';
import 'package:second_brain/features/notes/domain/usecases/create_note.dart';
import 'package:second_brain/features/notes/domain/usecases/delete_note.dart';
import 'package:second_brain/features/notes/domain/usecases/get_all_notes.dart';
import 'package:second_brain/features/notes/domain/usecases/search_notes.dart';
import 'package:second_brain/features/notes/domain/usecases/update_note.dart';

// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// Datasource provider
final notesLocalDatasourceProvider = Provider<NotesLocalDatasource>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return NotesLocalDatasource(sharedPrefs);
});

// Repository provider
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final datasource = ref.watch(notesLocalDatasourceProvider);
  return NotesRepositoryImpl(datasource);
});

// Use cases providers
final getAllNotesProvider = Provider<GetAllNotes>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return GetAllNotes(repository);
});

final createNoteProvider = Provider<CreateNote>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return CreateNote(repository);
});

final updateNoteProvider = Provider<UpdateNote>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return UpdateNote(repository);
});

final deleteNoteProvider = Provider<DeleteNote>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return DeleteNote(repository);
});

final searchNotesProvider = Provider<SearchNotes>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return SearchNotes(repository);
});

// Notes state notifier
class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    return await _loadNotes();
  }

  Future<List<Note>> _loadNotes() async {
    final getAllNotes = ref.read(getAllNotesProvider);
    return await getAllNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _loadNotes();
    });
  }

  Future<void> addNote(String title, String content, {String? color}) async {
    final createNote = ref.read(createNoteProvider);
    
    try {
      await createNote(title: title, content: content, color: color);
      await loadNotes();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateNote(Note note) async {
    final updateNoteUseCase = ref.read(updateNoteProvider);
    
    try {
      await updateNoteUseCase(note);
      await loadNotes();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteNote(String id) async {
    final deleteNoteUseCase = ref.read(deleteNoteProvider);
    
    try {
      await deleteNoteUseCase(id);
      await loadNotes();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> searchNotes(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final searchNotesUseCase = ref.read(searchNotesProvider);
      return await searchNotesUseCase(query);
    });
  }
}

// Notes provider
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(() {
  return NotesNotifier();
});

// Selected note provider (for editor screen)
final selectedNoteProvider = StateProvider<Note?>((ref) => null);

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered notes provider (combines notes + search query)
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  if (searchQuery.trim().isEmpty) {
    return notesAsync;
  }

  return notesAsync.when(
    data: (notes) {
      final lowerQuery = searchQuery.toLowerCase();
      final filtered = notes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(lowerQuery);
        final contentMatch = note.content.toLowerCase().contains(lowerQuery);
        return titleMatch || contentMatch;
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../data/datasources/notes_local_datasource.dart'; // Import Datasource
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferencesProvider (initialized in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences before using provider.');
});

// -----------------------------------------------------------------------------
// NEW: Datasource Provider
// -----------------------------------------------------------------------------
final notesLocalDatasourceProvider = Provider<NotesLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotesLocalDatasource(prefs);
});

// -----------------------------------------------------------------------------
// UPDATED: Repository Provider (Now injects the Datasource)
// -----------------------------------------------------------------------------
final notesRepositoryProvider = Provider<NotesRepositoryImpl>((ref) {
  final datasource = ref.watch(notesLocalDatasourceProvider);
  return NotesRepositoryImpl(datasource);
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Semantic search toggle provider
final semanticSearchToggleProvider = StateProvider<bool>((ref) => false);

// Notes AsyncNotifier
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    return _fetchAllNotes();
  }

  Future<List<Note>> _fetchAllNotes() async {
    final repo = ref.read(notesRepositoryProvider);
    return await repo.getAllNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAllNotes());
  }

  Future<void> addNote(String title, String content) async {
    final repo = ref.read(notesRepositoryProvider);
    final now = DateTime.now();

    final newNote = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    await repo.createNote(newNote);

    // Refresh to show new state
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateNote(Note note) async {
    final repo = ref.read(notesRepositoryProvider);
    final updatedNote = note.copyWith(updatedAt: DateTime.now());

    await repo.updateNote(updatedNote);

    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteNote(String id) async {
    final repo = ref.read(notesRepositoryProvider);
    await repo.deleteNote(id);

    ref.invalidateSelf();
    await future;
  }
}

// Filtered notes provider
final filteredNotesProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final useSemantic = ref.watch(semanticSearchToggleProvider);
  final repo = ref.read(notesRepositoryProvider);

  final allNotesAsync = await ref.watch(notesProvider.future);

  if (query.isEmpty) {
    return allNotesAsync;
  } else {
    if (useSemantic) {
      return await repo.semanticSearchNotes(query);
    } else {
      return await repo.searchNotes(query);
    }
  }
});
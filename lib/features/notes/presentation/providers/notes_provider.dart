import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/notes_repository_impl.dart';
// For shared preferences:
import 'package:shared_preferences/shared_preferences.dart';

// Notes repository provider (singleton)
final notesRepositoryProvider = Provider<NotesRepositoryImpl>((ref) => NotesRepositoryImpl());

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Notes provider: get all notes
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.read(notesRepositoryProvider);
  return await repo.getAllNotes();
});

// Filtered notes provider for search
final filteredNotesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.read(notesRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return await repo.getAllNotes();
  } else {
    return await repo.searchNotes(query);
  }
});

// Semantic search toggle provider
final semanticSearchToggleProvider = StateProvider<bool>((ref) => false);

// Notes search provider (handles semantic/normal search based on toggle)
final notesSearchProvider = FutureProvider.autoDispose.family<List<Note>, String>((ref, query) async {
  final notesRepo = ref.read(notesRepositoryProvider);
  final useSemanticSearch = ref.watch(semanticSearchToggleProvider);

  if (useSemanticSearch) {
    return await notesRepo.semanticSearchNotes(query);
  } else {
    return await notesRepo.searchNotes(query);
  }
});

// SharedPreferencesProvider (if you use SharedPreferences)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences before using provider.');
});
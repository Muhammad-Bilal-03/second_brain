import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/notes_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notes repository provider (singleton)
final notesRepositoryProvider = Provider<NotesRepositoryImpl>((ref) => NotesRepositoryImpl());

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Semantic search toggle provider
final semanticSearchToggleProvider = StateProvider<bool>((ref) => false);

// -----------------------------------------------------------------------------
// REFACTORED: Converted to AsyncNotifierProvider to support .notifier access
// -----------------------------------------------------------------------------
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

  /// Reload notes explicitly
  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAllNotes());
  }

  /// Add a new note
  Future<void> addNote(String title, String content) async {
    final repo = ref.read(notesRepositoryProvider);
    final now = DateTime.now();

    // Create new note with generated ID (using timestamp for simplicity)
    final newNote = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    await repo.createNote(newNote);

    // Refresh the list to reflect changes
    ref.invalidateSelf();
    await future;
  }

  /// Update an existing note
  Future<void> updateNote(Note note) async {
    final repo = ref.read(notesRepositoryProvider);
    final updatedNote = note.copyWith(updatedAt: DateTime.now());

    await repo.updateNote(updatedNote);

    ref.invalidateSelf();
    await future;
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    final repo = ref.read(notesRepositoryProvider);
    await repo.deleteNote(id);

    ref.invalidateSelf();
    await future;
  }
}

// -----------------------------------------------------------------------------
// UPDATED: Filtered provider now watches notesProvider for updates
// -----------------------------------------------------------------------------
final filteredNotesProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final useSemantic = ref.watch(semanticSearchToggleProvider);
  final repo = ref.read(notesRepositoryProvider);

  // Watch the main list so this provider updates automatically when notes are added/deleted
  final allNotesAsync = await ref.watch(notesProvider.future);

  if (query.isEmpty) {
    return allNotesAsync;
  } else {
    // Perform search
    if (useSemantic) {
      return await repo.semanticSearchNotes(query);
    } else {
      return await repo.searchNotes(query);
    }
  }
});

// SharedPreferencesProvider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences before using provider.');
});
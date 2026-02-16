import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../data/datasources/notes_local_datasource.dart';

// 1. SharedPreferences Dependency
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main.dart');
});

// 2. Data Sources & Repositories
final notesLocalDatasourceProvider = Provider<NotesLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotesLocalDatasource(prefs);
});

final notesRepositoryProvider = Provider<NotesRepositoryImpl>((ref) {
  final datasource = ref.watch(notesLocalDatasourceProvider);
  return NotesRepositoryImpl(datasource);
});

// 3. Search Query Notifier
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) {
    state = query;
  }
}

// 4. Semantic Search Toggle Notifier
final semanticSearchToggleProvider = NotifierProvider<SemanticSearchToggleNotifier, bool>(SemanticSearchToggleNotifier.new);

class SemanticSearchToggleNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Default: Off

  void toggle(bool value) {
    state = value;
  }
}

// 5. Notes Logic (The Main Brain)
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

  // UPDATED: Now accepts optional color
  Future<void> addNote(String title, String content, {String? color}) async {
    final repo = ref.read(notesRepositoryProvider);
    final now = DateTime.now();

    final newNote = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      color: color, // <--- Added Color
    );

    await repo.createNote(newNote);
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

// 6. Filtered Notes (The final output for UI)
final filteredNotesProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final useSemantic = ref.watch(semanticSearchToggleProvider);
  final repo = ref.read(notesRepositoryProvider);

  final allNotes = await ref.watch(notesProvider.future);

  if (query.isEmpty) {
    return allNotes;
  } else {
    if (useSemantic) {
      return await repo.semanticSearchNotes(query);
    } else {
      return await repo.searchNotes(query);
    }
  }
});
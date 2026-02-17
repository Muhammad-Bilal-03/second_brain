import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:second_brain/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:second_brain/features/notes/data/models/note_model.dart';
import 'package:second_brain/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:second_brain/features/notes/data/services/vector_search_service.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/domain/repositories/notes_repository.dart';

// --- Hive Box Provider (Overridden in main.dart) ---
final notesBoxProvider = Provider<Box<NoteModel>>((ref) {
  throw UnimplementedError('notesBoxProvider must be overridden in main.dart');
});

// --- Datasource ---
final notesLocalDataSourceProvider = Provider<NotesLocalDatasource>((ref) {
  final box = ref.watch(notesBoxProvider);
  return NotesLocalDatasourceImpl(box);
});

// --- Services ---
final vectorSearchServiceProvider = Provider<VectorSearchService>((ref) {
  return VectorSearchService();
});

// --- Repository ---
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final localDataSource = ref.watch(notesLocalDataSourceProvider);
  final vectorService = ref.watch(vectorSearchServiceProvider);
  return NotesRepositoryImpl(localDataSource, vectorService);
});

// --- Notifier ---
class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NotesRepository _repository;

  NotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      final notes = await _repository.getNotes();
      state = AsyncValue.data(notes);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addNote(String title, String content, {bool isPinned = false, String type = 'text', String? language, String? audioPath}) async {
    final newNote = Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: isPinned,
      type: type,
      language: language,
      audioPath: audioPath,
    );
    await _repository.saveNote(newNote);
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _repository.saveNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return NotesNotifier(repository);
});

// --- Search State ---
final searchQueryProvider = StateNotifierProvider<SearchQueryNotifier, String>((ref) {
  return SearchQueryNotifier();
});

class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');
  void update(String query) => state = query;
}

final semanticSearchToggleProvider = StateNotifierProvider<SemanticSearchToggleNotifier, bool>((ref) {
  return SemanticSearchToggleNotifier();
});

class SemanticSearchToggleNotifier extends StateNotifier<bool> {
  SemanticSearchToggleNotifier() : super(false);
  void toggle(bool value) => state = value;
}

// --- Filtered Notes (With Hybrid Search Fix) ---
final filteredNotesProvider = FutureProvider<List<Note>>((ref) async {
  // 1. Watch the AsyncValue directly
  final notesAsync = ref.watch(notesProvider);

  final query = ref.watch(searchQueryProvider).toLowerCase();
  final isSemantic = ref.watch(semanticSearchToggleProvider);
  final repository = ref.watch(notesRepositoryProvider);

  // 2. Safely unwrap the list. If loading/null, default to empty list.
  final List<Note> notes = notesAsync.valueOrNull ?? [];

  if (query.isEmpty) return notes;

  // 3. Hybrid Search Logic
  // Only use AI Semantic Search if the query is long enough (>= 3 chars).
  // This filters out noise like "p", "bu", "ch".
  if (isSemantic && query.length >= 3) {
    return await repository.semanticSearchNotes(query);
  }

  // 4. Fallback to Standard Search (Exact text match)
  // Used when Semantic Search is off OR when query is too short.
  return notes.where((note) {
    return note.title.toLowerCase().contains(query) ||
        note.content.toLowerCase().contains(query);
  }).toList();
});
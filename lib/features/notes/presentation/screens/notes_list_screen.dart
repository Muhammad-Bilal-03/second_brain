import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:second_brain/features/chat/presentation/screens/chat_screen.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/presentation/providers/notes_provider.dart';
import 'package:second_brain/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:second_brain/features/notes/presentation/widgets/empty_notes_widget.dart';
import 'package:second_brain/features/notes/presentation/widgets/note_card.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).update(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).update('');
  }

  // --- Creation Options (FAB Menu) ---
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Text Note'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewNote(type: 'text');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box_outlined),
                title: const Text('Checklist'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewNote(type: 'checklist');
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Code Snippet'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewNote(type: 'code');
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_none_outlined),
                title: const Text('Voice Note'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewNote(type: 'voice');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _createNewNote({required String type}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(initialType: type),
      ),
    );
    ref.invalidate(filteredNotesProvider);
  }

  void _navigateToEditor(Note note) async {
    if (_isSelectionMode) {
      _toggleSelection(note.id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
    );
    ref.invalidate(filteredNotesProvider);
  }

  void _openChat() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
  }

  // --- Selection ---
  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        if (_selectedNoteIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _enterSelectionMode(String noteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedNoteIds.add(noteId);
    });
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedNoteIds.toList();
    for (var id in ids) {
      await ref.read(notesProvider.notifier).deleteNote(id);
    }
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  Future<void> _pinSelected(List<Note> allNotes) async {
    if (_selectedNoteIds.isEmpty) return;
    final firstId = _selectedNoteIds.first;
    final firstNote = allNotes.firstWhere((n) => n.id == firstId);
    final shouldPin = !firstNote.isPinned;
    for (var id in _selectedNoteIds) {
      final note = allNotes.firstWhere((n) => n.id == id);
      await ref.read(notesProvider.notifier).updateNote(note.copyWith(isPinned: shouldPin));
    }
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notesAsync = ref.watch(filteredNotesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isSemanticSearch = ref.watch(semanticSearchToggleProvider);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          if (_isSelectionMode)
            SliverAppBar(
              pinned: true,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedNoteIds.clear();
                }),
              ),
              title: Text("${_selectedNoteIds.length} Selected"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.push_pin_outlined),
                  onPressed: () => notesAsync.whenData((notes) => _pinSelected(notes)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteSelected,
                ),
              ],
            )
          else
            SliverAppBar(
              floating: true,
              title: const Text("Second Brain 🧠"),
              titleTextStyle: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    onPressed: _openChat,
                    icon: Badge(
                      label: const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                      backgroundColor: theme.colorScheme.primary,
                      smallSize: 8,
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 26),
                    ),
                  ),
                ),
              ],
            ),

          if (!_isSelectionMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: isSemanticSearch ? 'Ask your brain...' : 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _clearSearch,
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.psychology,
                              color: isSemanticSearch ? theme.colorScheme.primary : Colors.grey,
                            ),
                            onPressed: () {
                              ref.read(semanticSearchToggleProvider.notifier).toggle(!isSemanticSearch);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return SliverFillRemaining(
                  child: searchQuery.isNotEmpty
                      ? const Center(child: Text('No notes found'))
                      : const EmptyNotesWidget(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final isSelected = _selectedNoteIds.contains(note.id);
                    return NoteCard(
                      note: note,
                      isSelected: isSelected,
                      onTap: () => _navigateToEditor(note),
                      onLongPress: () => _enterSelectionMode(note.id),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton.extended(
        onPressed: _showCreateOptions,
        label: const Text("Add Note"),
        icon: const Icon(Icons.add),
      )
          : null,
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Timer? _debounce;

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- Search Logic ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).update(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).update('');
  }

  Future<void> _refreshNotes() async {
    await ref.read(notesProvider.notifier).loadNotes();
  }

  // --- Navigation & Creation ---
  void _navigateToEditor({Note? note, String type = 'text'}) async {
    // If in selection mode, cancel it instead of navigating
    if (_isSelectionMode) {
      setState(() {
        _isSelectionMode = false;
        _selectedNoteIds.clear();
      });
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note, initialType: type),
      ),
    );
    _refreshNotes();
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(Icons.text_fields, "Text", 'text'),
              _buildOption(Icons.check_box_outlined, "Checklist", 'checklist'),
              _buildOption(Icons.mic, "Voice", 'voice'),
              _buildOption(Icons.image, "Image", 'image'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, String type) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close sheet
        if (type == 'image') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image notes coming soon!")));
        } else {
          _navigateToEditor(type: type);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- Selection Logic ---
  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        if (_selectedNoteIds.isEmpty) {
          _isSelectionMode = false;
        }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deleted ${ids.length} notes")));
    }
  }

  Future<void> _pinSelected(List<Note> allNotes) async {
    // Find selected notes and toggle their pin status (based on the first one)
    if (_selectedNoteIds.isEmpty) return;

    final firstId = _selectedNoteIds.first;
    final firstNote = allNotes.firstWhere((n) => n.id == firstId);
    final newPinState = !firstNote.isPinned; // Toggle

    for (var id in _selectedNoteIds) {
      final note = allNotes.firstWhere((n) => n.id == id);
      await ref.read(notesProvider.notifier).updateNote(note.copyWith(isPinned: newPinState));
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

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedNoteIds.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _isSelectionMode
                ? SliverAppBar(
              pinned: true,
              backgroundColor: theme.colorScheme.primaryContainer,
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
                  icon: const Icon(Icons.push_pin),
                  onPressed: () => notesAsync.whenData((notes) => _pinSelected(notes)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelected,
                ),
              ],
            )
                : SliverAppBar(
              floating: true,
              snap: true,
              title: Text(
                '🧠 Second Brain',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isSemanticSearch,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => ref.read(semanticSearchToggleProvider.notifier).toggle(val),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
          body: Column(
            children: [
              // Search Bar (Only show if not selecting)
              if (!_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(28),
                      border: isSemanticSearch
                          ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 1.5)
                          : null,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: isSemanticSearch ? 'Ask your brain...' : 'Search notes...',
                        prefixIcon: Icon(isSemanticSearch ? Icons.auto_awesome : Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSearch)
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshNotes,
                  child: notesAsync.when(
                    data: (notes) {
                      if (notes.isEmpty) {
                        return searchQuery.isNotEmpty
                            ? const Center(child: Text('No notes found'))
                            : const EmptyNotesWidget();
                      }

                      return MasonryGridView.count(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final isSelected = _selectedNoteIds.contains(note.id);

                          return NoteCard(
                            note: note,
                            isSelected: isSelected,
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(note.id);
                              } else {
                                _navigateToEditor(note: note, type: note.type);
                              }
                            },
                            onLongPress: () => _enterSelectionMode(note.id),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: !_isSelectionMode
            ? FloatingActionButton(
          onPressed: _showCreateOptions, // Opens the Bottom Sheet Menu
          child: const Icon(Icons.add),
        )
            : null, // Hide FAB when selecting
      ),
    );
  }
}
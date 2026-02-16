import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/presentation/providers/notes_provider.dart';
import 'package:second_brain/features/notes/data/services/voice_service.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  final VoiceService _voiceService = VoiceService();
  bool _isRecording = false;
  bool _isLocked = false;
  String _textBeforeRecording = '';
  StreamSubscription<String>? _voiceStatusSubscription;

  // Colors for the note
  final List<Color> _noteColors = [
    const Color(0xFFFFFFFF), // Default White
    const Color(0xFFFAE8E8), // Red
    const Color(0xFFFFF6D1), // Yellow
    const Color(0xFFE4F7D3), // Green
    const Color(0xFFD4EBF7), // Blue
    const Color(0xFFF3E5F5), // Purple
    const Color(0xFFF0F0F0), // Grey
  ];
  late Color _selectedColor;

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  late AnimationController _lockAnimController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    // Parse existing color
    if (widget.note?.color != null) {
      try {
        _selectedColor = Color(int.parse(widget.note!.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        _selectedColor = _noteColors[0];
      }
    } else {
      _selectedColor = _noteColors[0];
    }

    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);

    _lockAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    _initVoiceListener();
  }

  void _initVoiceListener() async {
    await _voiceService.initialize();
    _voiceStatusSubscription = _voiceService.statusStream.listen((status) {
      if (status == 'notListening' || status == 'done') {
        if (_isRecording && !_isLocked) {
          _stopRecordingUI();
        }
      }
    });
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _voiceService.stop();
    _voiceStatusSubscription?.cancel();
    _lockAnimController.dispose();
    super.dispose();
  }

  // --- Voice Logic ---

  void _startRecording() {
    if (_isRecording) return;
    _textBeforeRecording = _contentController.text;
    setState(() => _isRecording = true);
    _voiceService.startListening(onResult: (newText) {
      setState(() {
        final prefix = _textBeforeRecording.isEmpty ? "" : "$_textBeforeRecording ";
        _contentController.text = "$prefix$newText";
        _contentController.selection = TextSelection.fromPosition(TextPosition(offset: _contentController.text.length));
      });
    });
  }

  void _stopRecordingUI() {
    setState(() {
      _isRecording = false;
      _isLocked = false;
    });
    _lockAnimController.reverse();
  }

  void _stopRecording() async {
    await _voiceService.stop();
    _stopRecordingUI();
  }

  void _lockRecording() {
    setState(() => _isLocked = true);
    _lockAnimController.reverse();
  }

  // --- Note Logic ---

  void _toggleChecklist() {
    final text = _contentController.text;
    if (text.isEmpty) {
      _contentController.text = "[ ] ";
    } else {
      _contentController.text = "$text\n[ ] ";
    }
    _onContentChanged();
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot save an empty note')));
      return;
    }

    setState(() => _isSaving = true);

    // Correct color conversion
    final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2)}';

    try {
      final notesNotifier = ref.read(notesProvider.notifier);
      if (widget.note == null) {
        await notesNotifier.addNote(title, content, color: colorHex);
      } else {
        final updatedNote = widget.note!.copyWith(title: title, content: content, color: colorHex);
        await notesNotifier.updateNote(updatedNote);
      }
      setState(() { _hasUnsavedChanges = false; _isSaving = false; });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(notesProvider.notifier).deleteNote(widget.note!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _noteColors.length,
            itemBuilder: (context, index) {
              final color = _noteColors[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                    _hasUnsavedChanges = true;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.black : Colors.grey.shade300,
                      width: _selectedColor == color ? 3 : 1,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _selectedColor,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.palette), onPressed: _showColorPicker),
          if (isEditMode) IconButton(icon: const Icon(Icons.delete), onPressed: _deleteNote),
          IconButton(icon: const Icon(Icons.check_box), onPressed: _toggleChecklist),
          IconButton(
            icon: _isSaving ? const CircularProgressIndicator() : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
          ),
        ],
      ),
      backgroundColor: _selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              autofocus: !isEditMode,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none),
              textCapitalization: TextCapitalization.sentences,
            ),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: _isRecording ? 'Listening...' : 'Note content...',
                  hintStyle: _isRecording ? TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold) : null,
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onLongPressStart: (_) => _startRecording(),
        onLongPressEnd: (_) => _stopRecording(),
        onLongPressMoveUpdate: (details) {
          if (details.localOffsetFromOrigin.dy < -50) {
            _lockRecording();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _isRecording ? Colors.red : theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(
            _isLocked ? Icons.lock : (_isRecording ? Icons.mic_off : Icons.mic),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
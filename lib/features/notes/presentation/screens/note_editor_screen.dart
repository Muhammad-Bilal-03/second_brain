import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/presentation/providers/notes_provider.dart';
import 'package:second_brain/features/notes/data/services/voice_service.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  final String initialType; // 'text', 'checklist', 'voice'

  const NoteEditorScreen({super.key, this.note, this.initialType = 'text'});

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

  late String _noteType;
  bool _isPinned = false;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  late AnimationController _lockAnimController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _isPinned = widget.note?.isPinned ?? false;
    _noteType = widget.note?.type ?? widget.initialType;

    // Auto-init checklist if it's a checklist type and empty
    if (_noteType == 'checklist' && _contentController.text.isEmpty) {
      _contentController.text = "[ ] ";
    }

    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);

    _lockAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    _initVoiceListener();

    // Auto-start voice if type is voice
    if (_noteType == 'voice' && widget.note == null) {
      // We delay slightly to let UI build first
      Future.delayed(const Duration(milliseconds: 500), _startRecording);
    }
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

    // Simple Checklist Logic: If user presses enter, add "[ ] "
    if (_noteType == 'checklist') {
      final text = _contentController.text;
      if (text.endsWith('\n')) {
        // Avoid infinite loop by removing listener temporarily or checking cursor
        // For simple MVP, just adding it on next frame if not present
        if (!text.endsWith('\n[ ] ')) {
          // This is a basic implementation. A robust one requires FocusNode listening.
          // Keeping it simple for now: Manual toggle is safer.
        }
      }
    }
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

  // --- Actions ---
  void _toggleChecklist() {
    setState(() {
      _noteType = 'checklist';
    });
    final text = _contentController.text;
    if (text.isEmpty) {
      _contentController.text = "[ ] ";
    } else {
      _contentController.text = "$text\n[ ] ";
    }
    _onContentChanged();
  }

  void _togglePin() {
    setState(() {
      _isPinned = !_isPinned;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      // Allow empty save if it was just opened? No, prevent clutter.
      // But if we navigated back, we might want to delete it?
      // For now, just show message.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empty note discarded')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notesNotifier = ref.read(notesProvider.notifier);
      if (widget.note == null) {
        await notesNotifier.addNote(title, content, isPinned: _isPinned, type: _noteType);
      } else {
        final updatedNote = widget.note!.copyWith(
          title: title,
          content: content,
          isPinned: _isPinned,
          type: _noteType,
        );
        await notesNotifier.updateNote(updatedNote);
      }
      setState(() { _hasUnsavedChanges = false; _isSaving = false; });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: _isPinned ? 'Unpin' : 'Pin',
            onPressed: _togglePin,
          ),
          IconButton(
            icon: const Icon(Icons.check_box_outlined),
            onPressed: _toggleChecklist,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              autofocus: !isEditMode && _noteType == 'text',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                decoration: InputDecoration(
                  hintText: _isRecording ? 'Listening...' : 'Note content...',
                  hintStyle: _isRecording
                      ? TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                      : null,
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
      ),

      // Floating Mic Button Logic
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _isRecording ? Colors.red : theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Icon(
            _isLocked ? Icons.lock : (_isRecording ? Icons.stop : Icons.mic),
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
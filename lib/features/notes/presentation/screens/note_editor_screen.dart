import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:second_brain/features/notes/domain/entities/note.dart';
import 'package:second_brain/features/notes/presentation/providers/notes_provider.dart';
import 'package:second_brain/features/notes/data/services/voice_service.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  final String initialType;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.initialType = 'text',
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  // State
  late String _currentType;
  bool _hasUnsavedChanges = false;
  bool _isPinned = false;

  // Text Controllers
  late TextEditingController _titleController;
  late TextEditingController _textBodyController;

  // Code Controller
  late CodeController _codeController;

  // Checklist Data
  List<ChecklistItemController> _checklistItems = [];

  // Audio Data
  String? _audioPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Code Language State
  String _codeLanguage = 'dart';

  // Voice Service
  final VoiceService _voiceService = VoiceService();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _currentType = widget.note?.type ?? widget.initialType;
    _isPinned = widget.note?.isPinned ?? false;
    _audioPath = widget.note?.audioPath;
    _codeLanguage = widget.note?.language ?? 'dart';

    // 1. Initialize Text Controllers
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _textBodyController = TextEditingController(text: widget.note?.content ?? '');

    // 2. Initialize Code Controller
    _codeController = CodeController(
      text: widget.note?.content ?? '',
      language: _getLanguageMode(_codeLanguage),
    );

    // 3. Initialize Checklists
    if (_currentType == 'checklist') {
      _parseContentToChecklist(_textBodyController.text);
    }

    // 4. Listeners
    _titleController.addListener(_markChanged);
    _textBodyController.addListener(_markChanged);
    _codeController.addListener(_markChanged);

    _initServices();
  }

  void _initServices() async {
    await _voiceService.initialize();

    // Audio Player Listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  dynamic _getLanguageMode(String lang) {
    switch (lang) {
      case 'python': return python;
      case 'javascript': return javascript;
      default: return dart;
    }
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  // --- Checklist Parsing ---
  void _parseContentToChecklist(String content) {
    final lines = content.split('\n');
    _checklistItems = [];
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      bool isChecked = line.startsWith('- [x]');
      String text = line.replaceAll(RegExp(r'^- \[[ x]\] '), '');
      _checklistItems.add(ChecklistItemController(text: text, isChecked: isChecked));
    }
    if (_checklistItems.isEmpty) _checklistItems.add(ChecklistItemController());
  }

  void _syncChecklistToText() {
    final buffer = StringBuffer();
    for (var item in _checklistItems) {
      if (item.controller.text.trim().isEmpty) continue;
      final prefix = item.isChecked ? '- [x] ' : '- [ ] ';
      buffer.writeln('$prefix${item.controller.text}');
    }
    _textBodyController.text = buffer.toString().trim();
  }

  @override
  void dispose() {
    _voiceService.cancel();
    _audioPlayer.dispose();
    _titleController.dispose();
    _textBodyController.dispose();
    _codeController.dispose();
    for (var item in _checklistItems) {
      item.dispose();
    }
    super.dispose();
  }

  // --- Auto Save ---
  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges && widget.note != null) return;

    String finalContent = "";
    if (_currentType == 'checklist') {
      _syncChecklistToText();
      finalContent = _textBodyController.text;
    } else if (_currentType == 'code') {
      finalContent = _codeController.text;
    } else {
      finalContent = _textBodyController.text;
    }

    final title = _titleController.text.trim();
    if (widget.note == null && title.isEmpty && finalContent.isEmpty && _audioPath == null) return;

    try {
      final notifier = ref.read(notesProvider.notifier);
      if (widget.note == null) {
        await notifier.addNote(
          title,
          finalContent,
          isPinned: _isPinned,
          type: _currentType,
          language: _currentType == 'code' ? _codeLanguage : null,
          audioPath: _audioPath,
        );
      } else {
        final updated = widget.note!.copyWith(
          title: title,
          content: finalContent,
          isPinned: _isPinned,
          type: _currentType,
          language: _currentType == 'code' ? _codeLanguage : null,
          audioPath: _audioPath,
          updatedAt: DateTime.now(),
        );
        await notifier.updateNote(updated);
      }
    } catch (e) {
      debugPrint("Auto-save failed: $e");
    }
  }

  // --- Audio Actions (For Voice Notes) ---
  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      // Stop Recording & Save File
      final path = await _voiceService.stopRecordingFile();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _audioPath = path;
          _hasUnsavedChanges = true;
          // Reset player for new file
          _duration = Duration.zero;
          _position = Duration.zero;
        });
      }
    } else {
      // Start Recording File
      await _voiceService.startRecordingFile();
      setState(() => _isRecording = true);
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
    }
  }

  // --- Transcription Actions (For Text/Checklist Notes) ---
  void _startTranscription() {
    setState(() => _isRecording = true);
    _voiceService.startTranscription(onResult: (text) {
    });
  }

  void _stopTranscription() async {
    final text = await _voiceService.stopTranscription();
    if (text.isNotEmpty) {
      setState(() {
        if (_currentType == 'checklist') {
          _checklistItems.add(ChecklistItemController(text: text));
        } else {
          final current = _textBodyController.text;
          final spacer = (current.isNotEmpty && !current.endsWith('\n')) ? '\n' : '';
          _textBodyController.text = '$current$spacer$text';
        }
        _hasUnsavedChanges = true;
      });
    }
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCodeMode = _currentType == 'code';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _autoSave();
      },
      child: Scaffold(
        backgroundColor: isCodeMode ? const Color(0xFF1E1E1E) : theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isCodeMode ? Colors.white : null),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            if (isCodeMode)
              DropdownButton<String>(
                value: _codeLanguage,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                items: ['dart', 'python', 'javascript'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) {
                  setState(() {
                    _codeLanguage = val!;
                    _codeController.language = _getLanguageMode(val);
                    _hasUnsavedChanges = true;
                  });
                },
              ),
            IconButton(
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              color: _isPinned ? theme.colorScheme.primary : (isCodeMode ? Colors.white70 : null),
              onPressed: () => setState(() { _isPinned = !_isPinned; _hasUnsavedChanges = true; }),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TextField(
                controller: _titleController,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCodeMode ? Colors.white : null,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: isCodeMode ? const TextStyle(color: Colors.white30) : null,
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            // Main Editor Area
            Expanded(child: _buildEditor(theme)),
          ],
        ),

        // FAB logic
        floatingActionButton: _buildFAB(theme),
      ),
    );
  }

  Widget _buildFAB(ThemeData theme) {
    if (_currentType == 'code') return const SizedBox.shrink();

    // 1. Voice Note Mode -> Record Audio File
    if (_currentType == 'voice') {
      return FloatingActionButton.extended(
        onPressed: _toggleAudioRecording,
        backgroundColor: _isRecording ? Colors.red : theme.colorScheme.primary,
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        label: Text(_isRecording ? "Stop Recording" : "Record Audio"),
      );
    }

    // 2. Text/Checklist Mode -> Transcribe Text
    return GestureDetector(
      onLongPressStart: (_) => _startTranscription(),
      onLongPressEnd: (_) => _stopTranscription(),
      child: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hold to transcribe text"), duration: Duration(milliseconds: 1000)));
        },
        backgroundColor: _isRecording ? Colors.red : theme.colorScheme.primary,
        shape: const CircleBorder(),
        child: Icon(_isRecording ? Icons.mic_none : Icons.mic, color: Colors.white),
      ),
    );
  }

  Widget _buildEditor(ThemeData theme) {
    switch (_currentType) {
      case 'checklist':
        return _buildChecklistEditor(theme);
      case 'code':
        return _buildCodeEditor();
      case 'voice':
        return _buildVoicePlayerUI(theme);
      default:
        return _buildTextEditor(theme);
    }
  }

  // --- Editors ---

  Widget _buildCodeEditor() {
    return CodeTheme(
      data: CodeThemeData(styles: atomOneDarkTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _codeController,
          textStyle: GoogleFonts.firaCode(fontSize: 14),
          gutterStyle: GutterStyle(
            textStyle: GoogleFonts.firaCode(fontSize: 14, color: Colors.grey),
            showLineNumbers: true,
          ),
        ),
      ),
    );
  }

  Widget _buildVoicePlayerUI(ThemeData theme) {
    if (_audioPath == null && !_isRecording) {
      return const Center(child: Text("No audio recorded yet.", style: TextStyle(color: Colors.grey)));
    }

    if (_isRecording) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.graphic_eq, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text("Recording Audio...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 48, color: Colors.grey),
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                  iconSize: 64,
                  color: theme.colorScheme.primary,
                  onPressed: _togglePlayback,
                ),
                Expanded(
                  child: Slider(
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
              ],
            ),
            Text(
              "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  Widget _buildTextEditor(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _textBodyController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        decoration: const InputDecoration(
          hintText: 'Start typing...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 100),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildChecklistEditor(ThemeData theme) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 100, left: 10, right: 10),
      itemCount: _checklistItems.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) newIndex -= 1;
          final item = _checklistItems.removeAt(oldIndex);
          _checklistItems.insert(newIndex, item);
          _hasUnsavedChanges = true;
        });
      },
      footer: Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
        child: TextButton.icon(
          onPressed: () => setState(() {
            _checklistItems.add(ChecklistItemController());
            _hasUnsavedChanges = true;
          }),
          icon: const Icon(Icons.add),
          label: const Text("Add Item"),
        ),
      ),
      itemBuilder: (context, index) {
        final item = _checklistItems[index];
        return Padding(
          key: ValueKey(item),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
              Checkbox(
                value: item.isChecked,
                onChanged: (val) => setState(() { item.isChecked = val ?? false; _hasUnsavedChanges = true; }),
              ),
              Expanded(
                child: TextField(
                  controller: item.controller,
                  focusNode: item.focusNode,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'List item'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    color: item.isChecked ? theme.disabledColor : null,
                  ),
                  onSubmitted: (_) => setState(() { _checklistItems.add(ChecklistItemController()); _hasUnsavedChanges = true; }),
                  onChanged: (_) => _markChanged(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: () => setState(() {
                  _checklistItems[index].dispose();
                  _checklistItems.removeAt(index);
                  if (_checklistItems.isEmpty) _checklistItems.add(ChecklistItemController());
                  _hasUnsavedChanges = true;
                }),
              )
            ],
          ),
        );
      },
    );
  }
}

class ChecklistItemController {
  bool isChecked;
  late TextEditingController controller;
  late FocusNode focusNode;
  ChecklistItemController({String text = '', this.isChecked = false}) {
    controller = TextEditingController(text: text);
    focusNode = FocusNode();
  }
  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}
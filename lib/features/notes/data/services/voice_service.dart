import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _speech.initialize(
        onError: (e) => debugPrint('Speech Error: $e'),
      );
      _isInitialized = true;
    }
  }

  // --- Mode A: Transcription ---
  void startTranscription({required Function(String) onResult}) {
    if (!_isInitialized) return;
    _speech.listen(
      onResult: (val) => onResult(val.recognizedWords),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<String> stopTranscription() async {
    if (!_isInitialized) return "";
    await _speech.stop();
    return _speech.lastRecognizedWords;
  }

  // --- Mode B: File Recording ---
  Future<void> startRecordingFile() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final path = '${dir.path}/$fileName';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
      }
    } catch (e) {
      debugPrint("Audio Record Error: $e");
    }
  }

  Future<String?> stopRecordingFile() async {
    try {
      final path = await _audioRecorder.stop();
      return path;
    } catch (e) {
      debugPrint("Stop Record Error: $e");
      return null;
    }
  }

  void cancel() {
    _speech.cancel();
    _audioRecorder.dispose();
  }
}
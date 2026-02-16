import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  // NEW: A stream to let the UI know when status changes (listening/notListening/done)
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  Future<bool> initialize() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return false;

    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (val) => print('Voice Error: $val'),
        onStatus: (val) {
          print('Voice Status: $val');
          _statusController.add(val); // <--- Broadcast status to UI
        },
      );
    }
    return _isInitialized;
  }

  void startListening({required Function(String) onResult}) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
      localeId: 'en_US',
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  // Dispose controller when app closes (optional but good practice)
  void dispose() {
    _statusController.close();
  }

  bool get isListening => _speech.isListening;
}
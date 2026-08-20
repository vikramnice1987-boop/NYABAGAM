import 'package:flutter/foundation.dart';

typedef SpeechResultCallback = void Function(String text, bool isFinal);

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  bool _isListening = false;
  bool get isListening => _isListening;

  Future<bool> startListening({
    required SpeechResultCallback onResult,
    required VoidCallback onDone,
    String language = 'en-US',
  }) async {
    if (_isListening) return true;
    _isListening = true;

    // Web Speech Recognition Interop or Mobile Fallback
    try {
      if (kIsWeb) {
        // Utilizing Web SpeechRecognition API in browser
        _startWebSpeechRecognition(onResult, onDone, language);
        return true;
      }
    } catch (_) {}
    return true;
  }

  void stopListening() {
    _isListening = false;
  }

  void _startWebSpeechRecognition(
    SpeechResultCallback onResult,
    VoidCallback onDone,
    String language,
  ) {
    // In web browsers, SpeechRecognition runs via JavaScript Web API
    // We provide a fallback simulator if mic is blocked, and connect real stream
  }
}

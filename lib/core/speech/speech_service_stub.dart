import 'package:flutter/foundation.dart';
import 'speech_service_interface.dart';

class SpeechService implements BaseSpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  bool _isListening = false;
  @override
  bool get isListening => _isListening;

  @override
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    required VoidCallback onDone,
    String language = 'en-US',
  }) async {
    _isListening = true;
    return true;
  }

  @override
  void stopListening() {
    _isListening = false;
  }
}
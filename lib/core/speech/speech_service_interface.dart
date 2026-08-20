import 'package:flutter/foundation.dart';

typedef SpeechResultCallback = void Function(String text, bool isFinal);

abstract class BaseSpeechService {
  bool get isListening;
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    required VoidCallback onDone,
    String language = 'en-US',
  });
  void stopListening();
}
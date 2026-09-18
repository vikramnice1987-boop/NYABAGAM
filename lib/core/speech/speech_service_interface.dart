import 'package:flutter/foundation.dart';

typedef SpeechResultCallback = void Function(String text, bool isFinal);

abstract class BaseSpeechService {
  bool get isListening;

  /// Why the last attempt failed, for surfacing in the UI. Null when fine.
  String? get lastError => null;
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    required VoidCallback onDone,
    String language = 'en-US',
  });
  void stopListening();
}
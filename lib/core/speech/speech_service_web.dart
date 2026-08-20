import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'speech_service_interface.dart';

@JS('window')
external JSObject get _window;

class SpeechService implements BaseSpeechService {
  SpeechService._() {
    _setupWebListeners();
  }
  static final SpeechService instance = SpeechService._();

  bool _isListening = false;
  @override
  bool get isListening => _isListening;
  SpeechResultCallback? _callback;
  VoidCallback? _doneCallback;

  void _setupWebListeners() {
    try {
      final jsWindow = _window;
      final addListener = jsWindow.getProperty('addEventListener'.toJS) as JSFunction?;
      if (addListener != null) {
        final onResult = (JSAny? event) {
          try {
            final detail = (event as JSObject).getProperty('detail'.toJS);
            if (detail != null) {
              final text = detail.dartify()?.toString() ?? '';
              if (text.isNotEmpty) {
                _callback?.call(text, false);
              }
            }
          } catch (_) {}
        }.toJS;

        final onEnd = (JSAny? event) {
          _isListening = false;
          _doneCallback?.call();
        }.toJS;

        addListener.callAsFunction(jsWindow, 'nyabagam_speech_result'.toJS, onResult);
        addListener.callAsFunction(jsWindow, 'nyabagam_speech_end'.toJS, onEnd);
        addListener.callAsFunction(jsWindow, 'nyabagam_speech_error'.toJS, onEnd);
      }
    } catch (_) {}
  }

  @override
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    required VoidCallback onDone,
    String language = 'en-US',
  }) async {
    _callback = onResult;
    _doneCallback = onDone;
    _isListening = true;

    try {
      final speechObj = _window.getProperty('nyabagamSpeech'.toJS) as JSObject?;
      if (speechObj != null) {
        final startFunc = speechObj.getProperty('start'.toJS) as JSFunction?;
        if (startFunc != null) {
          startFunc.callAsFunction(speechObj, language.toJS);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Speech start error: $e');
    }
    return true;
  }

  @override
  void stopListening() {
    _isListening = false;
    try {
      final speechObj = _window.getProperty('nyabagamSpeech'.toJS) as JSObject?;
      if (speechObj != null) {
        final stopFunc = speechObj.getProperty('stop'.toJS) as JSFunction?;
        if (stopFunc != null) {
          stopFunc.callAsFunction(speechObj);
        }
      }
    } catch (_) {}
    _doneCallback?.call();
  }
}
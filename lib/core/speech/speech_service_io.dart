import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'speech_service_interface.dart';

/// On-device speech recognition for Android, iOS, Windows and macOS.
///
/// Replaces the old no-op stub, which accepted `startListening` and then never
/// emitted a result or a completion, so on a real phone the microphone button
/// appeared to work while nothing was ever transcribed.
class SpeechService implements BaseSpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _initialised = false;
  bool _available = false;
  bool _isListening = false;

  // The engine is initialised once, but every screen that starts a session
  // supplies its own callbacks. These are held in fields and refreshed on each
  // `startListening` so the long-lived onStatus/onError handlers registered at
  // initialise time always dispatch to the *current* listener rather than to a
  // stale closure from a disposed widget.
  SpeechResultCallback? _onResult;
  VoidCallback? _onDone;

  @override
  String? lastError;

  @override
  bool get isListening => _isListening;

  void _finish() {
    if (!_isListening) return;
    _isListening = false;
    _onDone?.call();
  }

  Future<bool> _ensureInitialised() async {
    if (_initialised) return _available;

    try {
      _available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[SpeechService] status: $status');
          // Only 'done' is terminal. Android fires 'notListening' as soon as
          // it stops capturing audio, which is *before* the final result
          // arrives - ending the session there truncates the transcript and
          // leaves the engine running.
          if (status == 'done') _finish();
        },
        onError: (error) {
          lastError = error.errorMsg;
          debugPrint(
            '[SpeechService] error: ${error.errorMsg} '
            '(permanent: ${error.permanent})',
          );
          // A no-match/timeout on one utterance is recoverable; the engine
          // keeps going. Only tear the session down on permanent errors.
          if (error.permanent) _finish();
        },
      );
    } catch (e) {
      lastError = e.toString();
      _available = false;
      debugPrint('[SpeechService] initialize failed: $e');
    }

    _initialised = true;
    if (!_available) {
      lastError ??= 'Speech recognition is unavailable on this device.';
    }
    return _available;
  }

  /// speech_to_text expects locale ids like `en_IN`; the app stores `en-IN`.
  String _normaliseLocale(String language) => language.replaceAll('-', '_');

  /// Picks the closest locale the engine actually supports, falling back to the
  /// language subtag (e.g. `ta`) and finally to the device default, so an
  /// unsupported region code does not silently produce zero results.
  Future<String?> _resolveLocale(String language) async {
    final wanted = _normaliseLocale(language).toLowerCase();
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return null;

      for (final l in locales) {
        if (l.localeId.toLowerCase() == wanted) return l.localeId;
      }
      final prefix = wanted.split('_').first;
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith(prefix)) return l.localeId;
      }
      debugPrint('[SpeechService] locale $wanted unsupported; using default');
    } catch (e) {
      debugPrint('[SpeechService] locale lookup failed: $e');
    }
    return null;
  }

  @override
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    required VoidCallback onDone,
    String language = 'en-US',
  }) async {
    lastError = null;

    // Refresh before initialising: a failure inside initialize() must report
    // to the caller that is asking right now.
    _onResult = onResult;
    _onDone = onDone;

    final ready = await _ensureInitialised();
    if (!ready) {
      _isListening = false;
      onDone();
      return false;
    }

    // Never stack two sessions on one engine.
    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    final localeId = await _resolveLocale(language);

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            _onResult?.call(words, result.finalResult);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          // Partial results stream words as they are spoken, which is what
          // makes the live transcript feel responsive.
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          // A single "no match" must not kill the whole session.
          cancelOnError: false,
          // Long enough for a full memory note, with a generous pause so a
          // moment of thinking does not end the capture.
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 6),
        ),
      );
      return true;
    } catch (e) {
      lastError = e.toString();
      _isListening = false;
      debugPrint('[SpeechService] listen failed: $e');
      onDone();
      return false;
    }
  }

  @override
  void stopListening() {
    if (!_isListening) return;
    _isListening = false;
    try {
      // Yields any buffered final result before the engine shuts down.
      _speech.stop();
    } catch (e) {
      debugPrint('[SpeechService] stop failed: $e');
    }
  }
}

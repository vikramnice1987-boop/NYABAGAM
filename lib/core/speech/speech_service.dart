// Web uses the browser SpeechRecognition API wired up in web/index.html;
// every other platform uses on-device recognition via speech_to_text.
//
// This used to fall back to a no-op stub off the web, which is why voice
// capture silently did nothing on Android and iOS.
export 'speech_service_io.dart'
    if (dart.library.js_interop) 'speech_service_web.dart';

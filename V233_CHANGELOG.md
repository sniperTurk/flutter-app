# V233

- Added a production iOS microphone bridge boundary for chronograph PCM using Flutter MethodChannel/EventChannel.
- Added strict Dart decoding for normalized mono PCM, sample rate, and absolute sample offsets; malformed native payloads fail closed.
- Added app-owned Swift AVAudioEngine capture reference and deterministic scaffold installer.
- Added NSMicrophoneUsageDescription to deterministic iOS metadata configuration.
- The bridge is installed only after the real Flutter iOS scaffold is generated. It is not claimed compiled or device-validated in this environment.
- No raw audio persistence was added.

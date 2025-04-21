class AudioParams {
  static final int channels1 = 1;

  static final String formatOpus = 'opus';

  static final int frameDuration60 = 60;

  static final int sampleRate16000 = 16000;

  final int channels;

  final String format;

  final int frameDuration;

  final int sampleRate;

  AudioParams({
    required this.channels,
    required this.format,
    required this.frameDuration,
    required this.sampleRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'channels': channels,
      'format': format,
      'frame_duration': frameDuration,
      'sample_rate': sampleRate,
    };
  }

  factory AudioParams.fromJson(Map<String, dynamic> json) {
    return AudioParams(
      channels: json['channels'],
      format: json['format'],
      frameDuration: json['frame_duration'],
      sampleRate: json['sample_rate'],
    );
  }
}

class WebsocketMessage {
  static final String typeHello = 'hello';

  static final String typeSpeechToText = 'stt';

  static final String typeTextToSpeech = 'tts';

  static final String typeLLM = 'llm';

  static final String typeIOT = 'iot';

  static final String typeListen = 'listen';

  static final String transportWebSocket = 'websocket';

  static final String stateStart = 'start';

  static final String stateStop = 'stop';

  static final String stateSentenceStart = 'sentence_start';

  static final String stateSentenceEnd = 'sentence_end';

  static final String emotionHappy = 'happy';

  static final String modeAuto = 'auto';

  static final String modeManual = 'manual';

  static final String modeRealtime = 'realtime';

  final String type;

  final String? transport;

  final int? version;

  final AudioParams? audioParams;

  final String? sessionId;

  final String? state;

  final String? emotion;

  final String? text;

  final String? mode;

  WebsocketMessage({
    required this.type,
    this.transport,
    this.version,
    this.audioParams,
    this.sessionId,
    this.state,
    this.emotion,
    this.text,
    this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'version': version,
      'transport': transport,
      'audio_params': audioParams?.toJson(),
      'session_id': sessionId,
      'state': state,
      'emotion': emotion,
      'text': text,
      'mode': mode,
    };
  }

  Map<String, dynamic> toHelloJson() {
    return {
      'type': type,
      'version': version,
      'transport': transport,
      'audio_params': audioParams?.toJson(),
    };
  }

  Map<String, dynamic> toEventJson() {
    return {
      'type': type,
      'state': state,
      'session_id': sessionId,
      'mode': mode,
    };
  }

  factory WebsocketMessage.fromJson(Map<String, dynamic> json) {
    return WebsocketMessage(
      type: json['type'],
      transport: json['transport'],
      version: json['version'],
      audioParams:
          null == json['audio_params']
              ? null
              : AudioParams.fromJson(json['audio_params']),
      sessionId: json['session_id'],
      state: json['state'],
      emotion: json['emotion'],
      text: json['text'],
      mode: json['mode'],
    );
  }
}

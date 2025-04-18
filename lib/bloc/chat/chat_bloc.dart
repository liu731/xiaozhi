import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xiaozhi/util/common_utils.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  WebSocketChannel? _channel;

  StreamSubscription? _streamSubscription;

  AudioRecorder? _audioRecorder;

  Stream<Uint8List>? _audioStream;

  StreamSubscription<Uint8List>? _audioSubscription;

  String? sessionId;

  int? audioSampleRate;

  int? audioChannels;

  int? audioFrameDuration;

  ChatBloc() : super(ChatInitialState()) {
    on<ChatEvent>((event, emit) async {
      if (event is ChatInitialEvent) {
        try {
          _channel = IOWebSocketChannel.connect(
            Uri.parse('wss://2662r3426b.vicp.fun/xiaozhi/v1/'),
            headers: {
              "Protocol-Version": "1",
              "Device-Id": "94:a9:90:1b:66:f4",
              "Authorization":
                  "Bearer eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjE4MDM4NywidXNlcm5hbWUiOiIrODYxNTg5Nzc0MTk5MiIsInRlbGVwaG9uZSI6Iis4NjE1OCoqKioxOTkyIiwiaWF0IjoxNzQxNTY5MzkzLCJleHAiOjE3NDkzNDUzOTN9.-7vgSLOmepxPaleSYoSNGtlVcLXkh7WuE9GNKnbkIpG9jCM3jZtbxt34aZX-0WBMm6AbpOiEJbRgOvbHkJZGbw",
              "Client-Id": "acba69bf-4b23-4423-9aef-8112cf958f6b",
            },
          );

          _streamSubscription = _channel!.stream.listen(
            (message) {
              // Handle incoming messages
              print('Received message: $message');

              //{"type": "hello", "version": 1, "transport": "websocket", "audio_params": {"format": "opus", "sample_rate": 16000, "channels": 1, "frame_duration": 60}, "session_id": "927320e6-7bde-464f-84c3-51930746f077"}
              try {
                var json = jsonDecode(message);
                print(json);
                sessionId = json['session_id'];
                audioSampleRate = json['audio_params']['sample_rate'];
                audioChannels = json['audio_params']['channels'];
                audioFrameDuration = json['audio_params']['frame_duration'];
              } catch (e) {}
            },
            onError: (error) {
              // Handle errors
              print('WebSocket error: $error');
            },
            onDone: () {
              // Handle WebSocket closure
              print('WebSocket closed');
            },
          );

          _channel!.sink.add(
            '{"type":"hello","version":1,"transport":"websocket","audio_params":{"format":"opus","sample_rate":${audioSampleRate ?? 16000},"channels":1,"frame_duration":${audioFrameDuration ?? 60}}',
          );

          _audioRecorder = AudioRecorder();

          initOpus(await opus_flutter.load());
        } catch (e, s) {
          print(e);
          print(s);
        }
      }

      if (event is ChatStartListenEvent) {
        if (false ==
            (event.isRequestMicrophonePermission
                ? (await Permission.microphone.request().isGranted)
                : (await Permission.microphone.isGranted))) {
          emit(ChatNoMicrophonePermissionState());
          return;
        }

        _channel!.sink.add(
          '{"session_id":"${sessionId!}","type":"listen","state":"start","mode":"auto"}',
        );

        print('___FUCK');
        print(sessionId);
        print(audioSampleRate);
        print(audioChannels);
        print(audioFrameDuration);

        _audioStream = (await _audioRecorder!.startStream(
          RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            echoCancel: true,
            noiseSuppress: true,
            numChannels: audioChannels!,
            sampleRate: audioSampleRate!,
          ),
        ));

        _audioSubscription = _audioStream!.listen((data) async {
          if (_channel != null && data.isNotEmpty && data.length % 2 == 0) {
            Uint8List? opusData = await CommonUtils.pcmToOpus(
              pcmData: data,
              sampleRate: audioSampleRate!,
              frameDuration: audioFrameDuration!,
            );
            if (null != opusData) {
              print(opusData);
              _channel!.sink.add(opusData);
            }
          }
        });
      }
    });
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:taudio/public/fs/flutter_sound.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xiaozhi/model/storage_message.dart';
import 'package:xiaozhi/model/websocket_message.dart';
import 'package:xiaozhi/util/common_utils.dart';
import 'package:xiaozhi/util/storage_util.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  WebSocketChannel? _channel;

  StreamSubscription? _streamSubscription;

  AudioRecorder? _audioRecorder;

  FlutterSoundPlayer? _audioPlayer;

  Stream<Uint8List>? _audioStream;

  StreamSubscription<Uint8List>? _audioSubscription;

  String? _sessionId;

  int? _audioSampleRate;

  int? _audioChannels;

  int? _audioFrameDuration;

  final int _paginatedLimit = 20;

  int _paginatedOffset = 0;

  @override
  Future<void> close() {
    if (null != _streamSubscription) {
      _streamSubscription!.cancel();
      _streamSubscription = null;
    }
    if (null != _audioSubscription) {
      _audioSubscription!.cancel();
      _audioSubscription = null;
    }
    return super.close();
  }

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
            (data) async {
              try {
                if (data is String) {
                  final WebsocketMessage message = WebsocketMessage.fromJson(
                    jsonDecode(data),
                  );
                  if (null != message.sessionId) {
                    _sessionId = message.sessionId;
                  }
                  if (null != message.audioParams) {
                    _audioSampleRate = message.audioParams!.sampleRate;
                    _audioChannels = message.audioParams!.channels;
                    _audioFrameDuration = message.audioParams!.frameDuration;
                  }

                  if (message.type == WebsocketMessage.typeSpeechToText &&
                      null != _audioRecorder) {
                    await _audioRecorder!.stop();

                    if (null != message.text) {
                      add(
                        ChatOnMessageEvent(
                          message: StorageMessage(
                            id: Uuid().v4(),
                            text: message.text!,
                            sendByMe: true,
                            createdAt: DateTime.now(),
                          ),
                        ),
                      );
                    }
                  } else if (message.type ==
                          WebsocketMessage.typeTextToSpeech &&
                      message.state == WebsocketMessage.stateSentenceStart &&
                      null != message.text) {
                    add(
                      ChatOnMessageEvent(
                        message: StorageMessage(
                          id: Uuid().v4(),
                          text: message.text!,
                          sendByMe: false,
                          createdAt: DateTime.now(),
                        ),
                      ),
                    );
                  }
                } else if (data is Uint8List) {
                  if (false == _audioPlayer!.isOpen()) {
                    await _audioPlayer!.openPlayer();
                  }

                  if (_audioPlayer!.isPlaying) {
                    _audioPlayer!.uint8ListSink!.add(
                      (await CommonUtils.opusToPcm(
                        opusData: data,
                        sampleRate: _audioSampleRate!,
                        channels: _audioChannels!,
                      ))!,
                    );
                  } else {
                    await _audioPlayer!.startPlayerFromStream(
                      codec: Codec.pcm16,
                      interleaved: false,
                      numChannels: _audioChannels!,
                      sampleRate: _audioSampleRate!,
                      bufferSize: 1024,
                    );
                  }
                }
              } catch (e, s) {
                print('___Error');
                print(e);
                print(s);
              }
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
            jsonEncode(
              WebsocketMessage(
                type: WebsocketMessage.typeHello,
                transport: WebsocketMessage.transportWebSocket,
                audioParams: AudioParams(
                  sampleRate: _audioSampleRate ?? AudioParams.sampleRate16000,
                  channels: _audioChannels ?? AudioParams.channels1,
                  frameDuration:
                      _audioFrameDuration ?? AudioParams.frameDuration60,
                  format: AudioParams.formatOpus,
                ),
              ).toJson(),
            ),
          );

          _audioRecorder = AudioRecorder();

          _audioPlayer = FlutterSoundPlayer();

          initOpus(await opus_flutter.load());

          List<StorageMessage> messageList = await StorageUtil()
              .getPaginatedMessages(
                limit: _paginatedLimit,
                offset: _paginatedOffset,
              );

          emit(ChatInitialState(messageList: messageList));
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
          jsonEncode(
            WebsocketMessage(
              type: WebsocketMessage.typeListen,
              sessionId: _sessionId,
              state: WebsocketMessage.stateStart,
              mode: WebsocketMessage.modeAuto,
            ).toJson(),
          ),
        );

        _audioStream = (await _audioRecorder!.startStream(
          RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            echoCancel: true,
            noiseSuppress: true,
            numChannels: _audioChannels!,
            sampleRate: _audioSampleRate!,
          ),
        ));

        _audioSubscription = _audioStream!.listen((data) async {
          if (_channel != null && data.isNotEmpty && data.length % 2 == 0) {
            Uint8List? opusData = await CommonUtils.pcmToOpus(
              pcmData: data,
              sampleRate: _audioSampleRate!,
              frameDuration: _audioFrameDuration!,
            );
            if (null != opusData) {
              _channel!.sink.add(opusData);
            }
          }
        });
      }

      if (event is ChatOnMessageEvent) {
        await StorageUtil().insertMessage(event.message);
        emit(
          ChatInitialState(messageList: [event.message, ...state.messageList]),
        );
      }

      if (event is ChatLoadMoreEvent) {
        _paginatedOffset += _paginatedLimit;
        List<StorageMessage> messageList = await StorageUtil()
            .getPaginatedMessages(limit: 20, offset: _paginatedOffset);
        emit(
          ChatInitialState(
            messageList: [...state.messageList, ...messageList],
            hasMore: messageList.length == _paginatedLimit,
          ),
        );
      }

      if (event is ChatStopListenEvent) {
        if (null != _audioRecorder && (await _audioRecorder!.isRecording())) {
          await _audioRecorder!.stop();
        }
      }
    });
  }
}

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
  WebSocketChannel? _websocketChannel;

  StreamSubscription? _websocketStreamSubscription;

  AudioRecorder? _audioRecorder;

  FlutterSoundPlayer? _audioPlayer;

  Stream<Uint8List>? _audioRecorderStream;

  StreamSubscription<Uint8List>? _audioRecorderSubscription;

  String? _sessionId;

  int _audioSampleRate = AudioParams.sampleRate16000;

  int _audioChannels = AudioParams.channels1;

  int _audioFrameDuration = AudioParams.frameDuration60;

  final int _messageListPaginatedLimit = 20;

  int _messageListPaginatedOffset = 0;

  bool _isOnCall = false;

  @override
  Future<void> close() {
    if (null != _websocketStreamSubscription) {
      _websocketStreamSubscription!.cancel();
      _websocketStreamSubscription = null;
    }
    if (null != _audioRecorderSubscription) {
      _audioRecorderSubscription!.cancel();
      _audioRecorderSubscription = null;
    }
    return super.close();
  }

  void _initWebsocketListener() {
    _websocketStreamSubscription = _websocketChannel!.stream.listen(
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

            if (message.type == WebsocketMessage.typeSpeechToText) {
              if (null != _audioRecorder &&
                  await _audioRecorder!.isRecording()) {
                await _audioRecorder!.stop();
              }

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
            } else if (message.type == WebsocketMessage.typeTextToSpeech &&
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
            } else if (message.type == WebsocketMessage.typeTextToSpeech &&
                message.state == WebsocketMessage.stateStop &&
                _isOnCall) {
              add(ChatStartListenEvent());
            }
          } else if (data is Uint8List) {
            if (false == _audioPlayer!.isOpen()) {
              await _audioPlayer!.openPlayer();
            }

            if (_audioPlayer!.isPlaying) {
              _audioPlayer!.uint8ListSink!.add(
                (await CommonUtils.opusToPcm(
                  opusData: data,
                  sampleRate: _audioSampleRate,
                  channels: _audioChannels,
                ))!,
              );
            } else {
              await _audioPlayer!.startPlayerFromStream(
                codec: Codec.pcm16,
                interleaved: false,
                numChannels: _audioChannels,
                sampleRate: _audioSampleRate,
                bufferSize: 1024,
              );
            }
          }
        } catch (e, s) {
          print('___ERROR Listen $s $e');
        }
      },
      onError: (e) {
        print('___ERROR Websocket $e');
      },
      onDone: () {
        print('___INFO Websocket Closed');
        if (null != _websocketStreamSubscription) {
          _websocketStreamSubscription!.cancel();
          _websocketStreamSubscription = null;
        }
      },
    );
  }

  ChatBloc() : super(ChatInitialState()) {
    on<ChatEvent>((event, emit) async {
      if (event is ChatInitialEvent) {
        try {
          _websocketChannel = IOWebSocketChannel.connect(
            Uri.parse('wss://2662r3426b.vicp.fun/xiaozhi/v1/'),
            headers: {
              "Protocol-Version": "1",
              "Device-Id": "94:a9:90:1b:66:f4",
              "Authorization":
                  "Bearer eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjE4MDM4NywidXNlcm5hbWUiOiIrODYxNTg5Nzc0MTk5MiIsInRlbGVwaG9uZSI6Iis4NjE1OCoqKioxOTkyIiwiaWF0IjoxNzQxNTY5MzkzLCJleHAiOjE3NDkzNDUzOTN9.-7vgSLOmepxPaleSYoSNGtlVcLXkh7WuE9GNKnbkIpG9jCM3jZtbxt34aZX-0WBMm6AbpOiEJbRgOvbHkJZGbw",
              "Client-Id": "acba69bf-4b23-4423-9aef-8112cf958f6b",
            },
          );

          _initWebsocketListener();

          _websocketChannel!.sink.add(
            jsonEncode(
              WebsocketMessage(
                type: WebsocketMessage.typeHello,
                transport: WebsocketMessage.transportWebSocket,
                audioParams: AudioParams(
                  sampleRate: _audioSampleRate,
                  channels: _audioChannels,
                  frameDuration: _audioFrameDuration,
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
                limit: _messageListPaginatedLimit,
                offset: _messageListPaginatedOffset,
              );

          emit(ChatInitialState(messageList: messageList));
        } catch (e, s) {
          print('___ERROR ChatInitialEvent $e $s');
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

        if (null == _websocketStreamSubscription) {
          _initWebsocketListener();
        }

        _websocketChannel!.sink.add(
          jsonEncode(
            WebsocketMessage(
              type: WebsocketMessage.typeListen,
              sessionId: _sessionId,
              state: WebsocketMessage.stateStart,
              mode: WebsocketMessage.modeAuto,
            ).toJson(),
          ),
        );

        _audioRecorderStream = (await _audioRecorder!.startStream(
          RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            echoCancel: true,
            noiseSuppress: true,
            numChannels: _audioChannels,
            sampleRate: _audioSampleRate,
          ),
        ));

        if (null != _audioRecorderSubscription) {
          _audioRecorderSubscription!.cancel();
          _audioRecorderSubscription = null;
        }

        _audioRecorderSubscription = _audioRecorderStream!.listen((data) async {
          if (_websocketChannel != null &&
              data.isNotEmpty &&
              data.length % 2 == 0) {
            Uint8List? opusData = await CommonUtils.pcmToOpus(
              pcmData: data,
              sampleRate: _audioSampleRate,
              frameDuration: _audioFrameDuration,
            );
            if (null != opusData) {
              _websocketChannel!.sink.add(opusData);
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
        _messageListPaginatedOffset += _messageListPaginatedLimit;
        List<StorageMessage> messageList = await StorageUtil()
            .getPaginatedMessages(
              limit: 20,
              offset: _messageListPaginatedOffset,
            );
        emit(
          ChatInitialState(
            messageList: [...state.messageList, ...messageList],
            hasMore: messageList.length == _messageListPaginatedLimit,
          ),
        );
      }

      if (event is ChatStopListenEvent) {
        if (null != _audioRecorder && (await _audioRecorder!.isRecording())) {
          await _audioRecorder!.stop();
        }
      }

      if (event is ChatStartCallEvent) {
        _isOnCall = true;
        add(ChatStartListenEvent());
      }

      if (event is ChatStopCallEvent) {
        _isOnCall = false;
        add(ChatStopListenEvent());
      }
    });
  }
}

part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent {}

class ChatInitialEvent extends ChatEvent {}

class ChatStartListenEvent extends ChatEvent {
  final bool isRequestMicrophonePermission;

  ChatStartListenEvent({this.isRequestMicrophonePermission = false});
}

class ChatOnMessageEvent extends ChatEvent {
  final StorageMessage message;

  ChatOnMessageEvent({required this.message});
}

class ChatLoadMoreEvent extends ChatEvent {}

class ChatStopListenEvent extends ChatEvent {}

class ChatStartCallEvent extends ChatEvent {}

class ChatStopCallEvent extends ChatEvent {}

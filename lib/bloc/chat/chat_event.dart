part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent {}

class ChatInitialEvent extends ChatEvent {}

class ChatStartListenEvent extends ChatEvent {
  final bool isRequestMicrophonePermission;

  ChatStartListenEvent({this.isRequestMicrophonePermission = false});
}

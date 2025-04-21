part of 'chat_bloc.dart';

@immutable
sealed class ChatState {
  final List<StorageMessage> messageList;

  const ChatState({this.messageList = const []});
}

final class ChatInitialState extends ChatState {
  const ChatInitialState({super.messageList});
}

final class ChatNoMicrophonePermissionState extends ChatState {
  const ChatNoMicrophonePermissionState({super.messageList});
}

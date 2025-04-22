part of 'chat_bloc.dart';

@immutable
sealed class ChatState {
  final List<StorageMessage> messageList;

  const ChatState({this.messageList = const []});
}

final class ChatInitialState extends ChatState {
  final bool hasMore;

  const ChatInitialState({this.hasMore = true, super.messageList});
}

final class ChatNoMicrophonePermissionState extends ChatState {
  const ChatNoMicrophonePermissionState({super.messageList});
}

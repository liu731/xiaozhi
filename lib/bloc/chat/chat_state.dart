part of 'chat_bloc.dart';

@immutable
sealed class ChatState {}

final class ChatInitialState extends ChatState {}

final class ChatNoMicrophonePermissionState extends ChatState {}

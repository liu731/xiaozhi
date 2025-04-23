part of 'ota_bloc.dart';

@immutable
sealed class OtaState {}

final class OtaActivatedState extends OtaState {}

final class OtaNotActivatedState extends OtaState {
  final String code;

  final String? url;

  OtaNotActivatedState({required this.code, this.url});
}

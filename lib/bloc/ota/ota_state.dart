part of 'ota_bloc.dart';

@immutable
sealed class OtaState {}

final class OtaInitialState extends OtaState {
  final String otaUrl;

  final String websocketUrl;

  final String? macAddress;

  final String? clientId;

  OtaInitialState({
    required this.otaUrl,
    required this.websocketUrl,
    this.macAddress,
    this.clientId,
  });
}

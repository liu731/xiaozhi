import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUtil {
  static final SharedPreferencesUtil _instance =
      SharedPreferencesUtil._internal();

  factory SharedPreferencesUtil() {
    return _instance;
  }

  SharedPreferencesUtil._internal();

  final String _keyOtaUrl = 'OTA_URL';
  final String _keyWebsocketUrl = 'WEBSOCKET_URL';
  final String _keyMacAddress = 'MAC_ADDRESS';
  final String _keyClientId = 'CLIENT_ID';

  Future<String?> getOtaUrl() async {
    return (await SharedPreferences.getInstance()).getString(_keyOtaUrl);
  }

  Future<bool> setOtaUrl(String value) async {
    return (await SharedPreferences.getInstance()).setString(_keyOtaUrl, value);
  }

  Future<String?> getWebsocketUrl() async {
    return (await SharedPreferences.getInstance()).getString(_keyWebsocketUrl);
  }

  Future<bool> setWebsocketUrl(String value) async {
    return (await SharedPreferences.getInstance()).setString(
      _keyWebsocketUrl,
      value,
    );
  }

  Future<String?> getMacAddress() async {
    return (await SharedPreferences.getInstance()).getString(_keyMacAddress);
  }

  Future<bool> setMacAddress(String value) async {
    return (await SharedPreferences.getInstance()).setString(
      _keyMacAddress,
      value,
    );
  }

  Future<String?> getClientId() async {
    return (await SharedPreferences.getInstance()).getString(_keyClientId);
  }

  Future<bool> setClientId(String value) async {
    return (await SharedPreferences.getInstance()).setString(
      _keyClientId,
      value,
    );
  }
}

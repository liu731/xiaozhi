import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaozhi/common/x_const.dart';
import 'package:xiaozhi/util/common_utils.dart';

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

  Future<void> init() async {
    String? otaUrl = await getOtaUrl();
    if (null == otaUrl) {
      await setOtaUrl(XConst.defaultOtaUrl);
    }

    String? websocketUrl = await getWebsocketUrl();
    if (null == websocketUrl) {
      await setWebsocketUrl(XConst.defaultWebsocketUrl);
    }

    String? macAddress = await getMacAddress();
    if (null == macAddress) {
      await setMacAddress(CommonUtils.generateUnicastMacAddress());
    }
  }

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
}

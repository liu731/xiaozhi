import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:xiaozhi/common/x_const.dart';
import 'package:xiaozhi/util/common_utils.dart';
import 'package:xiaozhi/util/shared_preferences_util.dart';

part 'ota_event.dart';
part 'ota_state.dart';

class OtaBloc extends Bloc<OtaEvent, OtaState> {
  OtaBloc()
    : super(
        OtaInitialState(
          otaUrl: XConst.defaultOtaUrl,
          websocketUrl: XConst.defaultWebsocketUrl,
        ),
      ) {
    on<OtaEvent>((event, emit) async {
      if (event is OtaInitialEvent) {
        String? otaUrl = await SharedPreferencesUtil().getOtaUrl();
        if (null == otaUrl) {
          otaUrl = XConst.defaultOtaUrl;
          await SharedPreferencesUtil().setOtaUrl(otaUrl);
        }

        String? websocketUrl = await SharedPreferencesUtil().getWebsocketUrl();
        if (null == websocketUrl) {
          websocketUrl = XConst.defaultWebsocketUrl;
          await SharedPreferencesUtil().setWebsocketUrl(websocketUrl);
        }

        String? macAddress = await SharedPreferencesUtil().getMacAddress();
        if (null == macAddress) {
          macAddress = CommonUtils.generateRandomMacAddress();
          await SharedPreferencesUtil().setMacAddress(macAddress);
        }

        String? clientId = await SharedPreferencesUtil().getClientId();
        if (null == clientId) {
          clientId = Uuid().v4();
          await SharedPreferencesUtil().setClientId(clientId);
        }

        emit(
          OtaInitialState(
            otaUrl: otaUrl,
            websocketUrl: websocketUrl,
            macAddress: macAddress,
            clientId: clientId,
          ),
        );
      }
    });
  }
}

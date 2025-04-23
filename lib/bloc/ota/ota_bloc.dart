import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:xiaozhi/common/x_const.dart';
import 'package:xiaozhi/util/shared_preferences_util.dart';

part 'ota_event.dart';
part 'ota_state.dart';

class OtaBloc extends Bloc<OtaEvent, OtaState> {
  final _dio = Dio();

  OtaBloc() : super(OtaActivatedState()) {
    on<OtaEvent>((event, emit) async {
      if (event is OtaInitialEvent) {
        try {
          Response response = await _dio.post(
            await SharedPreferencesUtil().getOtaUrl() ?? XConst.defaultOtaUrl,
            data: {
              "mac_address": await SharedPreferencesUtil().getMacAddress(),
              "application": {"name": XConst.name},
            },
            options: Options(
              headers: {
                "Device-Id": await SharedPreferencesUtil().getMacAddress(),
              },
            ),
          );
          if (null == response.data['activation']) {
            emit(OtaActivatedState());
          } else {
            String? url;
            try {
              String domain =
                  (response.data['activation']['message'] as String)
                      .split('\n')
                      .first;
              String? otaUrl = await SharedPreferencesUtil().getOtaUrl();
              if (null != otaUrl && otaUrl.contains('https')) {
                url = 'https://$domain';
              } else {
                url = 'http://$domain';
              }
            } catch (_) {}
            emit(
              OtaNotActivatedState(
                code: response.data['activation']['code'],
                url: url,
              ),
            );
          }
        } catch (e, s) {
          print('___ERROR OTA $e $s');
        }
      }
    });
  }
}

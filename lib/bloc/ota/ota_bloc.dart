import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'ota_event.dart';
part 'ota_state.dart';

class OtaBloc extends Bloc<OtaEvent, OtaState> {
  OtaBloc() : super(OtaInitialState()) {
    on<OtaEvent>((event, emit) async {
      if (event is OtaInitialEvent) {}
    });
  }
}

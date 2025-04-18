import 'dart:math';
import 'dart:typed_data';

import 'package:opus_dart/opus_dart.dart';

class CommonUtils {
  static SimpleOpusEncoder? _simpleOpusEncoder;

  static String generateRandomMacAddress() {
    final random = Random();
    final bytes = List<int>.generate(6, (_) => random.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  static Future<Uint8List?> pcmToOpus({
    required Uint8List pcmData,
    required int sampleRate,
    required int frameDuration,
  }) async {
    try {
      _simpleOpusEncoder ??= SimpleOpusEncoder(
        sampleRate: sampleRate,
        channels: 1,
        application: Application.voip,
      );

      final Int16List pcmInt16 = Int16List.fromList(
        List.generate(
          pcmData.length ~/ 2,
          (i) => (pcmData[i * 2]) | (pcmData[i * 2 + 1] << 8),
        ),
      );

      final int samplesPerFrame = (sampleRate * frameDuration) ~/ 1000;

      Uint8List encoded;

      if (pcmInt16.length < samplesPerFrame) {
        final Int16List paddedData = Int16List(samplesPerFrame);
        for (int i = 0; i < pcmInt16.length; i++) {
          paddedData[i] = pcmInt16[i];
        }

        encoded = Uint8List.fromList(
          _simpleOpusEncoder!.encode(input: paddedData),
        );
      } else {
        encoded = Uint8List.fromList(
          _simpleOpusEncoder!.encode(
            input: pcmInt16.sublist(0, samplesPerFrame),
          ),
        );
      }

      return encoded;
    } catch (e, s) {
      print('Error encoding PCM to Opus: $e $s');
      return null;
    }
  }
}

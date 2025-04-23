import 'dart:math';
import 'dart:typed_data';

import 'package:opus_dart/opus_dart.dart';

class CommonUtils {
  static SimpleOpusEncoder? _simpleOpusEncoder;

  static SimpleOpusDecoder? _simpleOpusDecoder;

  static String generateUnicastMacAddress() {
    final rand = Random();
    List<int> macBytes = List.generate(6, (_) => rand.nextInt(256));
    macBytes[0] = (macBytes[0] & 0xFE) | 0x02;
    return macBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
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

  static Future<Uint8List?> opusToPcm({
    required Uint8List opusData,
    required int sampleRate,
    required int channels,
  }) async {
    try {
      _simpleOpusDecoder ??= SimpleOpusDecoder(
        sampleRate: sampleRate,
        channels: channels,
      );

      final Int16List pcmData = _simpleOpusDecoder!.decode(input: opusData);

      final Uint8List pcmBytes = Uint8List(pcmData.length * 2);
      ByteData bytes = ByteData.view(pcmBytes.buffer);

      for (int i = 0; i < pcmData.length; i++) {
        bytes.setInt16(i * 2, pcmData[i], Endian.little);
      }

      return pcmBytes;
    } catch (e, s) {
      print('Error encoding PCM to Opus: $e $s');
      return null;
    }
  }
}

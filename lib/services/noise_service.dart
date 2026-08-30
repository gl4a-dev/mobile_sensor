import 'dart:math';
import 'package:record/record.dart';

import '../models/noise.dart';


class NoiseService {
	final AudioRecorder _recorder = AudioRecorder();

	Future<NoiseMeasurement> measureNoise() async {
		final hasPermission = await _recorder.hasPermission();

		if (!hasPermission) {
			throw Exception(
				'Permission to use the microphone denied.',
			);
		}

		const sampleRate = 16000;
		const channels = 1;

		final stream = await _recorder.startStream(
			const RecordConfig(
				encoder: AudioEncoder.pcm16bits,
				sampleRate: sampleRate,
				numChannels: channels,
			),
		);

		final samples = <int>[];

		final subscription = stream.listen((data) {
			for (int i = 0; i + 1 < data.length; i += 2) {
				final sample = data[i] | (data[i + 1] << 8);
				final signedSample = sample > 32767 ? sample - 65536 : sample;

				samples.add(signedSample);
			}
		});

		await Future.delayed(
			const Duration(seconds: 1),
		);

		await subscription.cancel();
		await _recorder.stop();

		if (samples.isEmpty) {
			throw Exception(
				'No audio sample obtained.',
			);
		}

		double sumSquares = 0;

		for (final sample in samples) {
			sumSquares += sample * sample;
		}

		final rms = sqrt(sumSquares / samples.length);

		if (rms <= 0) {
			return const NoiseMeasurement(
				rms: 0,
				db: 0,
			);
		}

		final normalizedRms = rms / 32768.0;
		final db = 20 * log(normalizedRms) / ln10;

		return NoiseMeasurement(
			rms: rms,
			db: db,
		);
	}

	Future<void> dispose() async {
		await _recorder.dispose();
	}
}
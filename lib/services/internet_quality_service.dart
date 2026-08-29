import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/internet_quality.dart';

class PingResult {
	final double averagePingMs;
	final double jitterMs;
	final double successRate;

	PingResult({
		required this.averagePingMs,
		required this.jitterMs,
		required this.successRate,
	});
}

class InternetQualityService {
	static const String _pingUrl = 'https://speed.cloudflare.com/__down?bytes=0';
	static const String _downloadUrl = 'https://speed.cloudflare.com/__down?bytes=1500000';
	static const String _uploadUrl = 'https://speed.cloudflare.com/__up';

	static const int _totalPings = 5;

	Future<InternetQuality> measureInternetQuality() async {
		final startedAt = DateTime.now();

		PingResult? pingMetrics;
		double? downloadMbps;
		double? uploadMbps;
		String? errorMessage;
		bool isSuccess = false;

		try {
			// 1. (5 Pings)
			pingMetrics = await _measurePingAndJitter();

			// 2. (~1.5 MB)
			downloadMbps = await _measureDownload();

			// 3. (~384 KB)
			uploadMbps = await _measureUpload();

			isSuccess = true;
		} catch (e) {
			errorMessage = e.toString();
		}

		final totalDuration = DateTime.now().difference(startedAt);

		return InternetQuality(
			ping: pingMetrics?.averagePingMs,
			jitter: pingMetrics?.jitterMs,
			pingSuccessRate: pingMetrics?.successRate,
			download: downloadMbps,
			upload: uploadMbps,
			startedAt: startedAt,
			duration: totalDuration,
			endpoint: 'speed.cloudflare.com',
			success: isSuccess,
			error: errorMessage,
		);
	}

	Future<PingResult> _measurePingAndJitter() async {
		final client = http.Client();
		final List<double> latencies = [];
		int successfulPings = 0;

		try {
			for (int i = 0; i < _totalPings; i++) {
				final stopwatch = Stopwatch()..start();
				try {
					final response = await client.get(Uri.parse(_pingUrl)).timeout(const Duration(seconds: 3));
					stopwatch.stop();

					if (response.statusCode == 200) {
						latencies.add(stopwatch.elapsedMilliseconds.toDouble());
						successfulPings++;
					}
				} catch (_) {
					// pass
				}

				if (i < _totalPings - 1) {
					await Future.delayed(const Duration(milliseconds: 100));
				}
			}
		} finally {
			client.close();
		}

		if (latencies.isEmpty) {
			throw Exception('Failed all ping tests (no connectivity)');
		}

		final double avgPing = latencies.reduce((a, b) => a + b) / latencies.length;

		double totalJitter = 0.0;
		if (latencies.length > 1) {
			for (int i = 0; i < latencies.length - 1; i++) {
				totalJitter += (latencies[i + 1] - latencies[i]).abs();
			}
			totalJitter /= (latencies.length - 1);
		}

		final double successRate = successfulPings / _totalPings;

		return PingResult(
			averagePingMs: avgPing,
			jitterMs: totalJitter,
			successRate: successRate,
		);
	}

	Future<double> _measureDownload() async {
		final stopwatch = Stopwatch()..start();
		final response = await http.get(Uri.parse(_downloadUrl)).timeout(const Duration(seconds: 10));
		stopwatch.stop();

		if (response.statusCode != 200) {
			throw Exception('Download Failure: Code ${response.statusCode}');
		}

		final bytesReceived = response.bodyBytes.length;
		final seconds = stopwatch.elapsedMilliseconds / 1000.0;

		if (seconds == 0) return 0.0;

		final megabits = (bytesReceived * 8) / 1000000.0;
		return megabits / seconds;
	}

	Future<double> _measureUpload() async {
		// Payload of ~384 KB (384 * 1024 bytes)
		final Uint8List payload = Uint8List(384 * 1024);

		final stopwatch = Stopwatch()..start();
		final response = await http.post(
			Uri.parse(_uploadUrl),
			body: payload,
		).timeout(const Duration(seconds: 10));

		stopwatch.stop();

		if (response.statusCode != 200) {
			throw Exception('UploadFailure: code ${response.statusCode}');
		}

		final bytesSent = payload.length;
		final seconds = stopwatch.elapsedMilliseconds / 1000.0;

		if (seconds == 0) return 0.0;

		final megabits = (bytesSent * 8) / 1000000.0;
		return megabits / seconds;
	}
}
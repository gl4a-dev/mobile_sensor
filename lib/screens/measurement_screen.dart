import 'dart:convert';
import 'package:flutter/material.dart';

import '../data/local_measurement_storage.dart';
import '../services/location_service.dart';
import '../services/measurement_service.dart';
import '../services/noise_service.dart';
import '../services/internet_quality_service.dart';
import '../services/wifi_scan_service.dart';
import '../services/network_status_service.dart';
import '../models/measurement.dart';


class MeasurementScreen extends StatefulWidget {
	const MeasurementScreen({super.key});

	@override
	State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
	late final MeasurementService _measurementService;
	final LocalMeasurementStorage _storage = LocalMeasurementStorage();

	bool _isLoading = false;
	Measurement? _lastMeasurement;
	String _rawJson = '// Waiting for sensor execution...';

	@override
	void initState() {
		super.initState();
		_measurementService = MeasurementService(
			locationService: LocationService(),
			wifiScanService: WifiScanService(),
			noiseService: NoiseService(),
			networkStatusService: NetworkStatusService(),
			internetQualityService: InternetQualityService(),
		);
	}

	Future<void> _runMeasurement() async {
		setState(() {
			_isLoading = true;
			_rawJson = '// Performing sensor data collection...';
		});

		try {
			final measurement = await _measurementService.createMeasurement();
			await _storage.saveMeasurement(measurement);

			if (!mounted) return;

			setState(() {
				_lastMeasurement = measurement;
				_rawJson = const JsonEncoder.withIndent('  ').convert(measurement.toMap());
			});
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_rawJson = '// STDERR:\n$e';
			});
		} finally {
			if (mounted) {
				setState(() => _isLoading = false);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('\$ ./sensor --record'),
			),
			body: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						ElevatedButton.icon(
							onPressed: _isLoading ? null : _runMeasurement,
							icon: _isLoading
								? const SizedBox(
									width: 18,
									height: 18,
									child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
								)
								: const Icon(Icons.play_arrow),
							label: Text(_isLoading ? 'COLLETING DATA...' : 'EXECUTE MEASUREMENT'),
						),
						const SizedBox(height: 16),
						if (_lastMeasurement != null) ...[
							_buildMetricsOverview(_lastMeasurement!),
							const SizedBox(height: 16),
						],
						Expanded(
							child: Container(
								padding: const EdgeInsets.all(12),
								decoration: BoxDecoration(
									color: const Color(0xFF010409),
									borderRadius: BorderRadius.circular(6),
									border: Border.all(color: const Color(0xFF30363D)),
								),
								child: SingleChildScrollView(
									child: SelectableText(
										_rawJson,
										style: const TextStyle(
											fontFamily: 'monospace',
											fontSize: 12,
											color: Color(0xFF7EE787), // Terminal Green
										),
									),
								),
							),
						),
					],
				),
			),
		);
	}

	Widget _buildMetricsOverview(Measurement m) {
		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: const Color(0xFF161B22),
				borderRadius: BorderRadius.circular(6),
				border: Border.all(color: const Color(0xFF30363D)),
			),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceAround,
				children: [
					_buildStat('PING', '${m.internetQuality?.ping?.toStringAsFixed(0) ?? "-"} ms'),
					_buildStat('DOWN', '${m.internetQuality?.download?.toStringAsFixed(1) ?? "-"} Mbps'),
					_buildStat('NOISE', '${m.noiseMeasurement?.db.toStringAsFixed(1) ?? "-"} dB'),
					_buildStat('WIFI NETS', '${m.wifiList?.networks.length ?? 0}'),
				],
			),
		);
	}

	Widget _buildStat(String label, String value) {
		return Column(
			children: [
				Text(
					label,
					style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8B949E)),
				),
				const SizedBox(height: 4),
				Text(
					value,
					style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold),
				),
			],
		);
	}
}
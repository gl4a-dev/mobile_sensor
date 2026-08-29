import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/measurement_service.dart';
import '../services/noise_service.dart';
import '../services/internet_quality_service.dart';
import '../services/wifi_scan_service.dart';
import '../services/network_status_service.dart';

class MeasurementScreen extends StatefulWidget {
	const MeasurementScreen({super.key});

	@override
	State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
	late final MeasurementService measurementService;

	bool loading = false;

	String result = 'No measurements taken.';

	@override
	void initState() {
		super.initState();

		measurementService = MeasurementService(
			locationService: LocationService(),
			wifiScanService: WifiScanService(),
			noiseService: NoiseService(),
			networkStatusService: NetworkStatusService(),
			internetQualityService: InternetQualityService(),
		);
	}

	Future<void> _performMeasurement() async {
		setState(() {
			loading = true;
			result = 'Taking measurement';
		});

		try {
			final measurement = await measurementService.createMeasurement();

			if (!mounted) return;

			setState(() {
				result = measurement.toString();
			});
		} catch (e) {
			if (!mounted) return;

			setState(() {
				result = 'Error:\n$e';
			});
		} finally {
			if (mounted) {
				setState(() {
					loading = false;
				});
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Mobile Sensor'),
			),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					children: [
						SizedBox(
							width: double.infinity,
							child: ElevatedButton(
								onPressed: loading ? null : _performMeasurement,
								child: Text(
									loading ? 'Taking...' : 'Take measurement',
								),
							),
						),
						const SizedBox(height: 20),
						Expanded(
							child: SingleChildScrollView(
								child: SelectableText(result),
							),
						),
					],
				),
			),
		);
	}
}
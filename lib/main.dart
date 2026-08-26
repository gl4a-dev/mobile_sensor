import 'package:flutter/material.dart';

import 'screens/measurement_screen.dart';

void main() {
	runApp(const MobileSensorApp());
}

class MobileSensorApp extends StatelessWidget {
	const MobileSensorApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			title: 'Mobile Sensor',
			home: const MeasurementScreen(),
		);
	}
}
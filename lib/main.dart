import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
	runApp(const MobileSensorApp());
}

class MobileSensorApp extends StatelessWidget {
	const MobileSensorApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			title: 'Sensor Dev Suite',
			theme: ThemeData.dark().copyWith(
				scaffoldBackgroundColor: const Color(0xFF0D1117),
				colorScheme: const ColorScheme.dark(
					primary: Color(0xFF58A6FF),
					surface: Color(0xFF161B22),
					onSurface: Color(0xFFC9D1D9),
				),
				appBarTheme: const AppBarTheme(
					backgroundColor: Color(0xFF161B22),
					elevation: 0,
					titleTextStyle: TextStyle(
						fontFamily: 'monospace',
						fontSize: 18,
						fontWeight: FontWeight.bold,
						color: Color(0xFF58A6FF),
					),
				),
				elevatedButtonTheme: ElevatedButtonThemeData(
					style: ElevatedButton.styleFrom(
						backgroundColor: const Color(0xFF238636),
						foregroundColor: Colors.white,
						textStyle: const TextStyle(
							fontFamily: 'monospace',
							fontWeight: FontWeight.bold,
						),
						padding: const EdgeInsets.symmetric(vertical: 16),
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(6),
						),
					),
				),
			),
			home: const DashboardScreen(),
		);
	}
}
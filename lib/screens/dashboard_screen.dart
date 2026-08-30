import 'package:flutter/material.dart';

import 'measurement_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';


class DashboardScreen extends StatefulWidget {
	const DashboardScreen({super.key});

	@override
	State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
	int _currentIndex = 0;

	final GlobalKey<HistoryScreenState> _historyKey = GlobalKey<HistoryScreenState>();
	final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();

	void _onTabTapped(int index) {
		setState(() {
			_currentIndex = index;
		});

		if (index == 1) {
			_historyKey.currentState?.loadHistory();
		} else if (index == 2) {
			_settingsKey.currentState?.loadSettings();
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: IndexedStack(
				index: _currentIndex,
				children: [
					const MeasurementScreen(),
					HistoryScreen(key: _historyKey),
					SettingsScreen(key: _settingsKey),
				],
			),
			bottomNavigationBar: BottomNavigationBar(
				currentIndex: _currentIndex,
				onTap: _onTabTapped,
				backgroundColor: const Color(0xFF161B22),
				selectedItemColor: const Color(0xFF58A6FF),
				unselectedItemColor: const Color(0xFF8B949E),
				selectedLabelStyle: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
				unselectedLabelStyle: const TextStyle(fontFamily: 'monospace'),
				items: const [
					BottomNavigationBarItem(
						icon: Icon(Icons.sensors),
						label: 'Run ()',
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.data_object),
						label: 'Logs []',
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.settings),
						label: 'Config {}',
					),
				],
			),
		);
	}
}
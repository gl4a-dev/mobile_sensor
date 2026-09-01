import 'package:flutter/material.dart';

import '../core/settings/user_preferences_storage.dart';
import '../core/settings/app_settings.dart';
import '../workers/background_scheduler_worker.dart';

class SettingsScreen extends StatefulWidget {
	const SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
	final UserPreferencesStorage _storage = UserPreferencesStorage();
	late AppSettings _settings;
	bool _isLoading = true;

	// Approximate average consumption per complete measurement with Cloudflare Speedtest (~1.88 MB)
	static const double _mbPerMeasurement = 1.88;

	@override
	void initState() {
		super.initState();
		loadSettings();
	}

	Future<void> loadSettings() async {
		setState(() => _isLoading = true);
		final loaded = await _storage.getSettings();
		if (!mounted) return;
		setState(() {
			_settings = loaded;
			_isLoading = false;
		});
	}

	Future<void> _updateSettings(AppSettings newSettings) async {
		setState(() => _settings = newSettings);
		await _storage.saveSettings(newSettings);
		await BackgroundSchedulerWorker.syncServiceState(newSettings);
	}

	double get _activeHoursPerDay {
		if (_settings.isIntermittent24h) return 24.0;

		final startMinutes = _settings.startTime.hour * 60 + _settings.startTime.minute;
		final endMinutes = _settings.endTime.hour * 60 + _settings.endTime.minute;

		if (endMinutes <= startMinutes) {
			return ((24 * 60 - startMinutes) + endMinutes) / 60.0;
		}
		return (endMinutes - startMinutes) / 60.0;
	}

	int get _measurementsPerActiveDay {
		if (_settings.intervalInMinutes <= 0) return 0;
		return ((_activeHoursPerDay * 60) / _settings.intervalInMinutes).floor();
	}

	double get _dailyDataUsageMB => _measurementsPerActiveDay * _mbPerMeasurement;
	double get _weeklyDataUsageMB => _dailyDataUsageMB * _settings.activeDays.length;
	double get _monthlyDataUsageMB => _weeklyDataUsageMB * 4.33; // Avarage of weeks per month

	String _formatMB(double mb) {
		if (mb >= 1024) {
			return '${(mb / 1024).toStringAsFixed(2)} GB';
		}
		return '${mb.toStringAsFixed(1)} MB';
	}

	Future<void> _selectTime(bool isStart) async {
		final initial = isStart ? _settings.startTime : _settings.endTime;
		final picked = await showTimePicker(
			context: context,
			initialTime: initial,
		);

		if (picked != null) {
			if (isStart) {
				_updateSettings(_settings.copyWith(startTime: picked));
			} else {
				_updateSettings(_settings.copyWith(endTime: picked));
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		if (_isLoading) {
			return const Scaffold(
				body: Center(child: CircularProgressIndicator()),
			);
		}

		return Scaffold(
			appBar: AppBar(
				title: const Text('settings.config {}'),
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.all(16.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						_buildSectionHeader('// BACKGROUND SERVICE STATUS'),
						_buildServiceToggle(),
						const SizedBox(height: 20),

						_buildSectionHeader('// DATA OVERHEAD ESTIMATOR'),
						_buildDataEstimatorCard(),
						const SizedBox(height: 20),

						_buildSectionHeader('// SAMPLING INTERVAL'),
						_buildIntervalSelector(),
						const SizedBox(height: 20),

						_buildSectionHeader('// ACTIVE TIME WINDOW'),
						_buildTimeWindowSection(),
						const SizedBox(height: 20),

						_buildSectionHeader('// ACTIVE DAYS OF WEEK'),
						_buildDaysOfWeekSelector(),
						const SizedBox(height: 20),

						_buildSectionHeader('// NETWORK CONSTRAINTS'),
						_buildNetworkOptions(),
					],
				),
			),
		);
	}

	Widget _buildSectionHeader(String title) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 8.0),
			child: Text(
				title,
				style: const TextStyle(
					fontFamily: 'monospace',
					fontSize: 12,
					fontWeight: FontWeight.bold,
					color: Color(0xFF58A6FF),
				),
			),
		);
	}

	Widget _buildServiceToggle() {
		return Material(
			color: const Color(0xFF161B22),
			borderRadius: BorderRadius.circular(6),
			clipBehavior: Clip.antiAlias,
			child: Container(
				decoration: BoxDecoration(
					borderRadius: BorderRadius.circular(6),
					border: Border.all(color: const Color(0xFF30363D)),
				),
				child: SwitchListTile(
					title: const Text(
						'Enable Autonomous Background Tasks',
						style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
					),
					subtitle: Text(
						_settings.isBackgroundServiceEnabled
							? 'Service status: RUNNING'
							: 'Service status: STOPPED',
						style: TextStyle(
							fontFamily: 'monospace',
							fontSize: 11,
							color: _settings.isBackgroundServiceEnabled
								? const Color(0xFF7EE787)
								: const Color(0xFFF85149),
						),
					),
					value: _settings.isBackgroundServiceEnabled,
					activeThumbColor: const Color(0xFF238636),
					onChanged: (val) => _updateSettings(_settings.copyWith(isBackgroundServiceEnabled: val)),
				),
			),
		);
	}

	Widget _buildDataEstimatorCard() {
		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: const Color(0xFF010409),
				borderRadius: BorderRadius.circular(6),
				border: Border.all(color: const Color(0xFF30363D)),
			),
			child: Column(
				children: [
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceAround,
						children: [
							_buildEstimatorStat('DAY (Active)', _formatMB(_dailyDataUsageMB)),
							_buildEstimatorStat('WEEK', _formatMB(_weeklyDataUsageMB)),
							_buildEstimatorStat('MONTH', _formatMB(_monthlyDataUsageMB)),
						],
					),
					const Divider(color: Color(0xFF30363D), height: 20),
					Text(
						'Est. Measurements: $_measurementsPerActiveDay/day | ~${_mbPerMeasurement}MB payload/run',
						style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8B949E)),
					),
				],
			),
		);
	}

	Widget _buildEstimatorStat(String label, String value) {
		return Column(
			children: [
				Text(
					label,
					style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8B949E)),
				),
				const SizedBox(height: 4),
				Text(
					value,
					style: const TextStyle(
						fontFamily: 'monospace',
						fontSize: 13,
						fontWeight: FontWeight.bold,
						color: Color(0xFF79C0FF),
					),
				),
			],
		);
	}

	Widget _buildIntervalSelector() {
		final intervals = [1, 5, 10, 15, 30, 60, 120];

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
			decoration: BoxDecoration(
				color: const Color(0xFF161B22),
				borderRadius: BorderRadius.circular(6),
				border: Border.all(color: const Color(0xFF30363D)),
			),
			child: DropdownButtonHideUnderline(
				child: DropdownButton<int>(
					value: intervals.contains(_settings.intervalInMinutes)
						? _settings.intervalInMinutes
						: 15,
					dropdownColor: const Color(0xFF161B22),
					isExpanded: true,
					style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13),
					items: intervals.map((int mins) {
						final label = mins < 60 ? '$mins min' : '${mins ~/ 60} hour(s)';
						return DropdownMenuItem<int>(
							value: mins,
							child: Text('Every $label'),
						);
					}).toList(),
					onChanged: (val) {
						if (val != null) {
							_updateSettings(_settings.copyWith(intervalInMinutes: val));
						}
					},
				),
			),
		);
	}

  	Widget _buildTimeWindowSection() {
		return Material(
			color: const Color(0xFF161B22),
			borderRadius: BorderRadius.circular(6),
			clipBehavior: Clip.antiAlias,
			child: Container(
				padding: const EdgeInsets.all(12),
				decoration: BoxDecoration(
					borderRadius: BorderRadius.circular(6),
					border: Border.all(color: const Color(0xFF30363D)),
				),
				child: Column(
					children: [
						CheckboxListTile(
							title: const Text(
								'Intermittent (24 Hours non-stop)',
								style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
							),
							value: _settings.isIntermittent24h,
							activeColor: const Color(0xFF58A6FF),
							contentPadding: EdgeInsets.zero,
							onChanged: (val) {
								if (val != null) {
									_updateSettings(_settings.copyWith(isIntermittent24h: val));
								}
							},
						),
						if (!_settings.isIntermittent24h) ...[
							const Divider(color: Color(0xFF30363D)),
							Row(
								mainAxisAlignment: MainAxisAlignment.spaceEvenly,
								children: [
									OutlinedButton.icon(
										icon: const Icon(Icons.schedule, size: 16),
										label: Text('START: ${_settings.startTime.format(context)}'),
										style: OutlinedButton.styleFrom(
											foregroundColor: const Color(0xFFC9D1D9),
											side: const BorderSide(color: Color(0xFF30363D)),
											textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11),
										),
										onPressed: () => _selectTime(true),
									),
									OutlinedButton.icon(
										icon: const Icon(Icons.schedule, size: 16),
										label: Text('END: ${_settings.endTime.format(context)}'),
										style: OutlinedButton.styleFrom(
											foregroundColor: const Color(0xFFC9D1D9),
											side: const BorderSide(color: Color(0xFF30363D)),
											textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11),
										),
										onPressed: () => _selectTime(false),
									),
								],
							),
						]
					],
				),
			),
		);
	}

	Widget _buildDaysOfWeekSelector() {
		final daysMap = {
			1: 'M',
			2: 'T',
			3: 'W',
			4: 'T',
			5: 'F',
			6: 'S',
			7: 'S',
		};

		return Row(
			mainAxisAlignment: MainAxisAlignment.spaceBetween,
			children: daysMap.entries.map((entry) {
				final dayInt = entry.key;
				final dayLabel = entry.value;
				final isSelected = _settings.activeDays.contains(dayInt);

				return InkWell(
				onTap: () {
					final newSet = Set<int>.from(_settings.activeDays);
					if (isSelected) {
					if (newSet.length > 1) newSet.remove(dayInt); // At least 1 day
					} else {
					newSet.add(dayInt);
					}
					_updateSettings(_settings.copyWith(activeDays: newSet));
				},
				borderRadius: BorderRadius.circular(4),
					child: Container(
						width: 40,
						height: 40,
						alignment: Alignment.center,
						decoration: BoxDecoration(
							color: isSelected ? const Color(0xFF1F6FEB) : const Color(0xFF161B22),
							borderRadius: BorderRadius.circular(4),
							border: Border.all(
								color: isSelected ? const Color(0xFF58A6FF) : const Color(0xFF30363D),
							),
						),
						child: Text(
							dayLabel,
							style: TextStyle(
								fontFamily: 'monospace',
								fontWeight: FontWeight.bold,
								color: isSelected ? Colors.white : const Color(0xFF8B949E),
							),
						),
					),
				);
			}).toList(),
		);
	}

  	Widget _buildNetworkOptions() {
		return Material(
			color: const Color(0xFF161B22),
			borderRadius: BorderRadius.circular(6),
			clipBehavior: Clip.antiAlias,
			child: Container(
				decoration: BoxDecoration(
					borderRadius: BorderRadius.circular(6),
					border: Border.all(color: const Color(0xFF30363D)),
				),
				child: SwitchListTile(
					title: const Text(
						'Speedtest Only on Wi-Fi',
						style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
					),
					subtitle: const Text(
						'Bypass download/upload stress tests when on Mobile Data (4G/5G).',
						style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8B949E)),
					),
					value: _settings.speedTestOnlyOnWifi,
					activeThumbColor: const Color(0xFF58A6FF),
					onChanged: (val) => _updateSettings(_settings.copyWith(speedTestOnlyOnWifi: val)),
				),
			),
		);
	}
}
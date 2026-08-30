import 'package:flutter/material.dart';


class AppSettings {
	final bool isBackgroundServiceEnabled;
	final int intervalInMinutes;
	final bool isIntermittent24h;
	final TimeOfDay startTime;
	final TimeOfDay endTime;
	final Set<int> activeDays; // 1 = Monday, 7 = Sunday
	final bool speedTestOnlyOnWifi;

	const AppSettings({
		required this.isBackgroundServiceEnabled,
		required this.intervalInMinutes,
		required this.isIntermittent24h,
		required this.startTime,
		required this.endTime,
		required this.activeDays,
		this.speedTestOnlyOnWifi = false,
	});

	factory AppSettings.defaultSettings() {
		return const AppSettings(
			isBackgroundServiceEnabled: false,
			intervalInMinutes: 15,
			isIntermittent24h: false,
			startTime: TimeOfDay(hour: 8, minute: 0),
			endTime: TimeOfDay(hour: 18, minute: 0),
			activeDays: {1, 2, 3, 4, 5},
			speedTestOnlyOnWifi: false,
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'isBackgroundServiceEnabled': isBackgroundServiceEnabled,
			'intervalInMinutes': intervalInMinutes,
			'isIntermittent24h': isIntermittent24h,
			'startTimeHour': startTime.hour,
			'startTimeMinute': startTime.minute,
			'endTimeHour': endTime.hour,
			'endTimeMinute': endTime.minute,
			'activeDays': activeDays.toList(),
			'speedTestOnlyOnWifi': speedTestOnlyOnWifi,
		};
	}

	factory AppSettings.fromMap(Map<String, dynamic> map) {
		return AppSettings(
			isBackgroundServiceEnabled: map['isBackgroundServiceEnabled'] as bool? ?? false,
			intervalInMinutes: map['intervalInMinutes'] as int? ?? 15,
			isIntermittent24h: map['isIntermittent24h'] as bool? ?? false,
			startTime: TimeOfDay(
				hour: map['startTimeHour'] as int? ?? 8,
				minute: map['startTimeMinute'] as int? ?? 0,
			),
			endTime: TimeOfDay(
				hour: map['endTimeHour'] as int? ?? 18,
				minute: map['endTimeMinute'] as int? ?? 0,
			),
			activeDays: (map['activeDays'] as List<dynamic>?)
					?.map((e) => e as int)
					.toSet() ?? {1, 2, 3, 4, 5},
			speedTestOnlyOnWifi: map['speedTestOnlyOnWifi'] as bool? ?? false,
		);
	}

	AppSettings copyWith({
		bool? isBackgroundServiceEnabled,
		int? intervalInMinutes,
		bool? isIntermittent24h,
		TimeOfDay? startTime,
		TimeOfDay? endTime,
		Set<int>? activeDays,
		bool? speedTestOnlyOnWifi,
	}) {
		return AppSettings(
			isBackgroundServiceEnabled: isBackgroundServiceEnabled ?? this.isBackgroundServiceEnabled,
			intervalInMinutes: intervalInMinutes ?? this.intervalInMinutes,
			isIntermittent24h: isIntermittent24h ?? this.isIntermittent24h,
			startTime: startTime ?? this.startTime,
			endTime: endTime ?? this.endTime,
			activeDays: activeDays ?? this.activeDays,
			speedTestOnlyOnWifi: speedTestOnlyOnWifi ?? this.speedTestOnlyOnWifi,
		);
	}
}
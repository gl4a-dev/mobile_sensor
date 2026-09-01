import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/settings/app_settings.dart';
import '../core/settings/user_preferences_storage.dart';
import '../data/local_measurement_storage.dart';
import '../services/internet_quality_service.dart';
import '../services/location_service.dart';
import '../services/measurement_service.dart';
import '../services/network_status_service.dart';
import '../services/noise_service.dart';
import '../services/wifi_scan_service.dart';

/// Mandatory top-level entry point for the Android Isolate
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
	DartPluginRegistrant.ensureInitialized();
	WidgetsFlutterBinding.ensureInitialized();

	final preferencesStorage = UserPreferencesStorage();
	final localStorage = LocalMeasurementStorage();

	final measurementService = MeasurementService(
		locationService: LocationService(),
		wifiScanService: WifiScanService(),
		noiseService: NoiseService(),
		networkStatusService: NetworkStatusService(),
		internetQualityService: InternetQualityService(),
	);

	Timer? timer;

	service.on('stopService').listen((event) {
		timer?.cancel();
		service.stopSelf();
	});

	service.on('updateSettings').listen((event) async {
		timer?.cancel();
		timer = await _scheduleNextRun(service, preferencesStorage, localStorage, measurementService);
	});

	// Executes an initial measurement cycle when starting the service
	await _runMeasurementCycle(service, preferencesStorage, localStorage, measurementService);

	timer = await _scheduleNextRun(service, preferencesStorage, localStorage, measurementService);
}

Future<Timer> _scheduleNextRun(
	ServiceInstance service,
	UserPreferencesStorage preferencesStorage,
	LocalMeasurementStorage localStorage,
	MeasurementService measurementService,
) async {
	final settings = await preferencesStorage.getSettings();
	final interval = Duration(
		minutes: settings.intervalInMinutes > 0 ? settings.intervalInMinutes : 15,
	);

	return Timer.periodic(interval, (timer) async {
		await _runMeasurementCycle(service, preferencesStorage, localStorage, measurementService);
	});
}

Future<void> _runMeasurementCycle(
	ServiceInstance service,
	UserPreferencesStorage preferencesStorage,
	LocalMeasurementStorage localStorage,
	MeasurementService measurementService,
) async {
	final currentSettings = await preferencesStorage.getSettings();

	if (!currentSettings.isBackgroundServiceEnabled) {
		service.stopSelf();
		return;
	}

	final now = DateTime.now();

	// 1. Active Days Check
	if (!currentSettings.activeDays.contains(now.weekday)) {
		_updateNotification(
			service, 'Outside active day (${_getWeekdayName(now.weekday)}).');
		return;
	}

	// 2. Time Window Check
	if (!currentSettings.isIntermittent24h) {
		final startMinutes = currentSettings.startTime.hour * 60 + currentSettings.startTime.minute;
		final endMinutes = currentSettings.endTime.hour * 60 + currentSettings.endTime.minute;
		final currentMinutes = now.hour * 60 + now.minute;

		bool isInWindow = false;
		if (endMinutes >= startMinutes) {
			isInWindow = currentMinutes >= startMinutes && currentMinutes <= endMinutes;
		} else {
			isInWindow = currentMinutes >= startMinutes || currentMinutes <= endMinutes;
		}

		if (!isInWindow) {
			_updateNotification(service, 'Outside configured time window.');
			return;
		}
	}

	// 3. Wi-Fi Check
	if (currentSettings.speedTestOnlyOnWifi) {
		final netStatus = await NetworkStatusService().getCurrentNetworkStatus();
		if (netStatus.connectionType != 'wifi') {
			_updateNotification(service, 'Skipped: Connected to mobile data (Wi-Fi only mode).');
			return;
		}
	}

	// 4. Executing sensor measurements
	try {
		_updateNotification(service, 'Collecting sensor data...');

		final measurement = await measurementService.createMeasurement();
		await localStorage.saveMeasurement(measurement);

		final hour = now.hour.toString().padLeft(2, '0');
		final min = now.minute.toString().padLeft(2, '0');
		_updateNotification(
			service,
			'Last collection: $hour:$min | Wi-Fi networks: ${measurement.wifiList?.networks.length ?? 0}',
		);
	} catch (e) {
		_updateNotification(service, 'Collection error: ${e.toString()}');
	}
}

void _updateNotification(ServiceInstance service, String text) {
	if (service is AndroidServiceInstance) {
		service.setForegroundNotificationInfo(
			title: 'Sensor Monitor Active',
			content: text,
		);
	}
}

String _getWeekdayName(int day) {
	const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
	return days[(day - 1) % 7];
}

class BackgroundSchedulerWorker {
	static const String notificationChannelId = 'sensor_background_channel';
	static const int notificationId = 888;

	static Future<void> initializeService() async {
		final service = FlutterBackgroundService();

		const AndroidNotificationChannel channel = AndroidNotificationChannel(
			notificationChannelId,
			'Sensor Background Monitor',
			description: 'Executes sensor measurements periodically in the background.',
			importance: Importance.low,
		);

		final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

		await flutterLocalNotificationsPlugin
			.resolvePlatformSpecificImplementation<
				AndroidFlutterLocalNotificationsPlugin>()
			?.createNotificationChannel(channel);

		await service.configure(
			androidConfiguration: AndroidConfiguration(
				onStart: onStart,
				autoStart: false,
				isForegroundMode: true,
				notificationChannelId: notificationChannelId,
				initialNotificationTitle: 'Sensor Monitor Active',
				initialNotificationContent: 'Waiting for next measurement cycle...',
				foregroundServiceNotificationId: notificationId,
			),
			iosConfiguration: IosConfiguration(
				autoStart: false,
				onForeground: onStart,
				onBackground: (_) async => true,
			),
		);
	}

	static Future<void> syncServiceState(AppSettings settings) async {
		final service = FlutterBackgroundService();
		final isRunning = await service.isRunning();

		if (settings.isBackgroundServiceEnabled) {
		if (!isRunning) {
			await service.startService();
		} else {
			service.invoke('updateSettings');
		}
		} else {
			if (isRunning) {
				service.invoke('stopService');
			}
		}
	}
}
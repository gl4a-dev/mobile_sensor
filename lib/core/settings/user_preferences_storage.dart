import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';


class UserPreferencesStorage {
	static const String _settingsKey = 'app_settings_config';

	Future<void> saveSettings(AppSettings settings) async {
		final prefs = await SharedPreferences.getInstance();
		final jsonString = jsonEncode(settings.toMap());
		await prefs.setString(_settingsKey, jsonString);
	}

	Future<AppSettings> getSettings() async {
		final prefs = await SharedPreferences.getInstance();
		final jsonString = prefs.getString(_settingsKey);

		if (jsonString == null) {
			return AppSettings.defaultSettings();
		}

		try {
			final Map<String, dynamic> map = jsonDecode(jsonString);
			return AppSettings.fromMap(map);
		} catch (_) {
			return AppSettings.defaultSettings();
		}
	}
}
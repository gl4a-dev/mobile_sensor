import 'dart:convert';

import 'location.dart';
import 'internet_quality.dart';
import 'network_status.dart';
import 'wifi_list.dart';
import 'noise.dart';


class Measurement {
	final String id;
	final DateTime timestamp;

	final Location? location;
	final InternetQuality? internetQuality;
	final NetworkStatus? networkStatus;
	final WifiList? wifiList;
	final NoiseMeasurement? noiseMeasurement;

	const Measurement({
		required this.id,
		required this.timestamp,
		this.location,
		this.networkStatus,
		this.internetQuality,
		this.wifiList,
		this.noiseMeasurement,
	});

	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'timestamp': timestamp.toIso8601String(),
			'location': location?.toMap(),
			'internet_quality': internetQuality?.toMap(),
			'network_status': networkStatus?.toMap(),
			'wifi_list': wifiList?.toMapList(),
			'noise_measurement': noiseMeasurement?.toMap(),
		};
	}

	String toJsonString() => jsonEncode(toMap());

	factory Measurement.fromMap(Map<String, dynamic> map) {
		return Measurement(
			id: map['id'] as String,
			timestamp: DateTime.parse(map['timestamp'] as String),
			location: map['location'] != null
				? Location.fromMap(map['location'] as Map<String, dynamic>)
				: null,
			internetQuality: map['internet_quality'] != null
				? InternetQuality.fromMap(map['internet_quality'] as Map<String, dynamic>)
				: null,
			networkStatus: map['network_status'] != null
				? NetworkStatus.fromMap(map['network_status'] as Map<String, dynamic>)
				: null,
			wifiList: map['wifi_list'] != null
				? WifiList.fromMapList(map['wifi_list'] as List<dynamic>)
				: null,
			noiseMeasurement: map['noise_measurement'] != null
				? NoiseMeasurement.fromMap(map['noise_measurement'] as Map<String, dynamic>)
				: null,
		);
	}

	factory Measurement.fromJsonString(String source) =>
		Measurement.fromMap(jsonDecode(source) as Map<String, dynamic>);

	@override
	String toString() {
		return 
'''
------ MEASUREMENT ------
$id
$timestamp

${location.toString()}

${networkStatus.toString()}

${internetQuality.toString()}

${wifiList.toString()}

${noiseMeasurement.toString()}

''';
	}
}

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

	@override
	String toString() {
		return '''
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

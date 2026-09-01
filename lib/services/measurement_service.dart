import '../models/measurement.dart';
import 'internet_quality_service.dart';
import 'location_service.dart';
import 'network_status_service.dart';
import 'noise_service.dart';
import 'wifi_scan_service.dart';


class MeasurementService {
	final LocationService locationService;
	final WifiScanService wifiScanService;
	final NoiseService noiseService;
	final NetworkStatusService networkStatusService;
	final InternetQualityService internetQualityService;

	const MeasurementService({
		required this.locationService,
		required this.wifiScanService,
		required this.noiseService,
		required this.networkStatusService,
		required this.internetQualityService,
	});

	Future<Measurement> createMeasurement() async {
		final location = await locationService.getCurrentLocation();
		final wifiNetworks = await wifiScanService.scanNetworks();
		// final noiseMeasurement = await noiseService.measureNoise();
		final networkStatus = await networkStatusService.getCurrentNetworkStatus();
		final internetQuality = await internetQualityService.measureInternetQuality();

		final measurement = Measurement(
			id: DateTime.now().microsecondsSinceEpoch.toString(),
			timestamp: DateTime.now(),

			location: location,
			noiseMeasurement: null,
			internetQuality: internetQuality,
			networkStatus: networkStatus,
			wifiList: wifiNetworks,
		);

		return measurement;
	}
}
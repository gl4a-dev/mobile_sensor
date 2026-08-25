import 'package:wifi_scan/wifi_scan.dart';
import '../models/wifi_network.dart';
import '../models/wifi_list.dart';

class WifiScanService {
	Future<WifiList> scanNetworks() async {
		final canScan = await WiFiScan.instance.canStartScan();

		if (canScan != CanStartScan.yes) {
			throw Exception('Não foi possível iniciar o scan: $canScan');
		}

		await WiFiScan.instance.startScan();
		final accessPoints = await WiFiScan.instance.getScannedResults();

		final networks = accessPoints.map((ap) {
			return WifiNetwork(
				ssid: ap.ssid,
				bssid: ap.bssid,
				rssi: ap.level,
			);
		}).toList();

		return WifiList(networks);
	}
}
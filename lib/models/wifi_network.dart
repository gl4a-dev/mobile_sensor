class WifiNetwork {
	final String ssid;
	final String bssid;
	final int rssi;

	WifiNetwork({
		required this.ssid,
		required this.bssid,
		required this.rssi,
	});

	@override
	String toString() {
		return 'SSID: $ssid | BSSID: $bssid | RSSI: $rssi';
	}
}
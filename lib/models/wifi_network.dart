class WifiNetwork {
	final String ssid;
	final String bssid;
	final int rssi;

	WifiNetwork({
		required this.ssid,
		required this.bssid,
		required this.rssi,
	});

	Map<String, dynamic> toMap() {
		return {
			'ssid': ssid,
			'bssid': bssid,
			'rssi': rssi,
		};
	}

	factory WifiNetwork.fromMap(Map<String, dynamic> map) {
		return WifiNetwork(
			ssid: map['ssid'] as String,
			bssid: map['bssid'] as String,
			rssi: map['rssi'] as int,
		);
	}

	@override
	String toString() {
		return 'SSID: $ssid | BSSID: $bssid | RSSI: $rssi';
	}
}
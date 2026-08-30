class NetworkStatus {
    final String connectionType;

    final String? connectedSsid;
    final String? connectedBssid;

    final bool isMetered;
    final bool hasInternet;
    final bool isValidated;

    final String? mobileOperator;
    final String? mobileCountryCode;
    final String? mobileNetworkCode;

    const NetworkStatus({
        required this.connectionType,
        this.connectedSsid,
        this.connectedBssid,
        this.isMetered = false,
        this.hasInternet = false,
        this.isValidated = false,
        this.mobileOperator,
        this.mobileCountryCode,
        this.mobileNetworkCode,
    });

	Map<String, dynamic> toMap() {
		return {
			'connection_type': connectionType,
			'connected_ssid': connectedSsid,
			'connected_bssid': connectedBssid,
			'is_metered': isMetered,
			'has_internet': hasInternet,
			'is_validated': isValidated,
			'mobile_operator': mobileOperator,
			'mobile_country_code': mobileCountryCode,
			'mobile_network_code': mobileNetworkCode,
		};
	}

	factory NetworkStatus.fromMap(Map<String, dynamic> map) {
		return NetworkStatus(
			connectionType: map['connection_type'] as String,
			connectedSsid: map['connected_ssid'] as String?,
			connectedBssid: map['connected_bssid'] as String?,
			isMetered: map['is_metered'] as bool? ?? false,
			hasInternet: map['has_internet'] as bool? ?? false,
			isValidated: map['is_validated'] as bool? ?? false,
			mobileOperator: map['mobile_operator'] as String?,
			mobileCountryCode: map['mobile_country_code'] as String?,
			mobileNetworkCode: map['mobile_network_code'] as String?,
		);
	}

    @override
    String toString() {
        return 
'''
----- NETWORK STATUS -----
Type: $connectionType
SSID: ${connectedSsid ?? "-"}
BSSID: ${connectedBssid ?? "-"}
Metered Connection: $isMetered
Internet available: $hasInternet
Internet validated: $isValidated
Operator: ${mobileOperator ?? "-"}
MCC: ${mobileCountryCode ?? "-"}
MNC: ${mobileNetworkCode ?? "-"}
''';
    }
}
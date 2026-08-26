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

    @override
    String toString() {
        return '''
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
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile_operator_info/mobile_operator_info.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../models/network_status.dart';


class NetworkStatusService {
	final Connectivity _connectivity = Connectivity();
	final NetworkInfo _networkInfo = NetworkInfo();
	final MobileOperatorInfo _mobileOperatorInfo = MobileOperatorInfo();

	Future<NetworkStatus> getCurrentNetworkStatus() async {
		final connectivity = await _connectivity.checkConnectivity();

		String connectionType = 'none';

		if (connectivity.contains(ConnectivityResult.wifi)) {
			connectionType = 'wifi';
		} else if (connectivity.contains(ConnectivityResult.mobile)) {
			connectionType = 'mobile';
		} else if (connectivity.contains(ConnectivityResult.ethernet)) {
			connectionType = 'ethernet';
		}

		String? ssid;
		String? bssid;

		if (connectionType == 'wifi') {
			ssid = await _networkInfo.getWifiName();
			bssid = await _networkInfo.getWifiBSSID();
		}

		bool hasInternet = false;
		if (connectionType != 'none') {
			try {
				final result = await InternetAddress.lookup('one.one.one.one')
					.timeout(const Duration(seconds: 3));
				hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
			} catch (_) {
				hasInternet = false;
			}
		}

		String? mobileOperator;
		String? mobileCountryCode;
		String? mobileNetworkCode;

		if (connectionType == 'mobile') {
			try {
				final operatorInfo = await _mobileOperatorInfo.getMobileOperatorInfo();
				mobileOperator = operatorInfo.networkOperatorName;
				mobileCountryCode = operatorInfo.mobileCountryCode;
				mobileNetworkCode = operatorInfo.mobileNetworkCode;
			} catch (_) {
				// pass
			}
		}


		return NetworkStatus(
			connectionType: connectionType,
			connectedSsid: ssid,
			connectedBssid: bssid,
			isMetered: connectionType == 'mobile',
			hasInternet: hasInternet,
			isValidated: hasInternet,
			mobileOperator: mobileOperator,
			mobileCountryCode: mobileCountryCode,
			mobileNetworkCode: mobileNetworkCode,
		);
	}
}
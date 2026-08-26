import 'package:connectivity_control/connectivity_control.dart' as connectivity_control;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile_operator_info/mobile_operator_info.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../models/network_status.dart';

class NetworkStatusService {
	final Connectivity _connectivity = Connectivity();
	final NetworkInfo _networkInfo = NetworkInfo();

	final connectivity_control.ConnectivityControl _connectivityControl = connectivity_control.ConnectivityControl();

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

		final activeNetworks = await _connectivityControl.getActiveNetworks();

		connectivity_control.NetworkInfo? activeNetwork;

		if (activeNetworks.isNotEmpty) {

			for (final network in activeNetworks) {
				final type = network.type.name;

				if (connectionType == 'wifi' && type == 'wifi') {
					activeNetwork = network;
					break;
				}

				if (connectionType == 'mobile' && type == 'cellular') {
					activeNetwork = network;
					break;
				}

				if (connectionType == 'ethernet' && type == 'ethernet') {
					activeNetwork = network;
					break;
				}
			}

			activeNetwork ??= activeNetworks.first;
		}

		final hasInternet = activeNetwork?.hasInternet ?? false;
		final isValidated = activeNetwork?.isValidated ?? false;
		final isMetered = activeNetwork?.isMetered ?? false;


		String? mobileOperator;
		String? mobileCountryCode;
		String? mobileNetworkCode;

		if (connectionType == 'mobile') {
			final operatorInfo = await _mobileOperatorInfo.getMobileOperatorInfo();

			mobileOperator = operatorInfo.networkOperatorName;
			mobileCountryCode = operatorInfo.mobileCountryCode;
			mobileNetworkCode = operatorInfo.mobileNetworkCode;
		}


		return NetworkStatus(
			connectionType: connectionType,
			connectedSsid: ssid,
			connectedBssid: bssid,
			isMetered: isMetered,
			hasInternet: hasInternet,
			isValidated: isValidated,
			mobileOperator: mobileOperator,
			mobileCountryCode: mobileCountryCode,
			mobileNetworkCode: mobileNetworkCode,
		);
	}
}
import 'package:geolocator/geolocator.dart';

import '../models/location.dart';

class LocationService {
	Future<Location> getCurrentLocation() async {
		final serviceEnabled = await Geolocator.isLocationServiceEnabled();

		if (!serviceEnabled) {
			throw Exception(
				'O serviço de localização está desativado.',
			);
		}

		var permission = await Geolocator.checkPermission();

		if (permission == LocationPermission.denied) {
			permission = await Geolocator.requestPermission();
		}

		if (permission == LocationPermission.denied) {
			throw Exception(
				'A permissão de localização foi negada.',
			);
		}

		if (permission == LocationPermission.deniedForever) {
			throw Exception(
				'A permissão de localização foi negada permanentemente.',
			);
		}

		final position = await Geolocator.getCurrentPosition();

		return Location(
			latitude: position.latitude,
			longitude: position.longitude,
			altitude: position.altitude,
			accuracy: position.accuracy,
			provider: null,
		);
	}
}
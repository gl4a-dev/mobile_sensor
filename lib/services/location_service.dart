import 'package:geolocator/geolocator.dart';

import '../models/location.dart';


class LocationService {
	Future<Location> getCurrentLocation() async {
		final serviceEnabled = await Geolocator.isLocationServiceEnabled();

		if (!serviceEnabled) {
			throw Exception(
				'Location services are disabled.',
			);
		}

		var permission = await Geolocator.checkPermission();

		if (permission == LocationPermission.denied) {
			permission = await Geolocator.requestPermission();
		}

		if (permission == LocationPermission.denied) {
			throw Exception(
				'Location permission was denied.',
			);
		}

		if (permission == LocationPermission.deniedForever) {
			throw Exception(
				'Location permission has been permanently denied.',
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
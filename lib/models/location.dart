class Location {
	final double latitude;
	final double longitude;
	final double accuracy;
	final double altitude;
	final String? provider;

	const Location({
		required this.latitude,
		required this.longitude,
		required this.accuracy,
		required this.altitude,
		this.provider,
	});

	@override
	String toString() {
		return '''
----- LOCATION -----
Latitude: $latitude
Longitude: $longitude
Altitude: $altitude m
Precision: $accuracy m
Provider: ${provider ?? "-"}
''';
	}
}
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

	Map<String, dynamic> toMap() {
		return {
		'latitude': latitude,
		'longitude': longitude,
		'accuracy': accuracy,
		'altitude': altitude,
		'provider': provider,
		};
	}

	factory Location.fromMap(Map<String, dynamic> map) {
		return Location(
			latitude: (map['latitude'] as num).toDouble(),
			longitude: (map['longitude'] as num).toDouble(),
			accuracy: (map['accuracy'] as num).toDouble(),
			altitude: (map['altitude'] as num).toDouble(),
			provider: map['provider'] as String?,
		);
	}

	@override
	String toString() {
		return 
'''
----- LOCATION -----
Latitude: $latitude
Longitude: $longitude
Altitude: $altitude m
Precision: $accuracy m
Provider: ${provider ?? "-"}
''';
	}
}
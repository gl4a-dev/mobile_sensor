class NoiseMeasurement {
	final double rms;
	final double db;

	const NoiseMeasurement({
		required this.rms,
		required this.db,
	});

	Map<String, dynamic> toMap() {
		return {
			'rms': rms,
			'db': db,
		};
	}

	factory NoiseMeasurement.fromMap(Map<String, dynamic> map) {
		return NoiseMeasurement(
			rms: (map['rms'] as num).toDouble(),
			db: (map['db'] as num).toDouble(),
		);
	}

	@override
	String toString() {
		return 
'''
----- NOISE -----
RMS: ${rms.toStringAsFixed(2)}
dB: ${db.toStringAsFixed(2)}
''';
	}
}
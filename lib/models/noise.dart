class NoiseMeasurement {
	final double? rms;
	final double? db;

	const NoiseMeasurement({
		this.rms,
		this.db,
	});

	Map<String, dynamic> toMap() {
		return {
			'rms': rms,
			'db': db,
		};
	}

	factory NoiseMeasurement.fromMap(Map<String, dynamic> map) {
		return NoiseMeasurement(
			rms: (map['rms'] as num?)?.toDouble(),
			db: (map['db'] as num?)?.toDouble(),
		);
	}

	@override
	String toString() {
		final rmsStr = rms != null ? rms!.toStringAsFixed(2) : '-';
		final dbStr = db != null ? db!.toStringAsFixed(2) : '-';

		return '''
----- NOISE -----
RMS: $rmsStr
dB: $dbStr
	''';
	}
}
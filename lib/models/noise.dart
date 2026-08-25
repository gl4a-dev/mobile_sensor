class NoiseMeasurement {
	final double rms;
	final double db;

	const NoiseMeasurement({
		required this.rms,
		required this.db,
	});

	@override
	String toString() {
		return '''
----- NOISE -----
RMS: ${rms.toStringAsFixed(2)}
dB: ${db.toStringAsFixed(2)}
''';
	}
}
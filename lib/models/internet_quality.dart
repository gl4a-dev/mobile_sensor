class InternetQuality {
	final double? ping;
	final double? jitter;
	final double? pingSuccessRate;
	final double? download;
	final double? upload;

	final DateTime startedAt;
	final Duration duration;
	final String endpoint;
	final bool success;
	final String? error;

	const InternetQuality({
		this.ping,
		this.jitter,
		this.pingSuccessRate,
		this.download,
		this.upload,
		required this.startedAt,
		required this.duration,
		required this.endpoint,
		required this.success,
		this.error,
	});

	@override
	String toString() {
		final successPct = pingSuccessRate != null ? '${(pingSuccessRate! * 100).toStringAsFixed(0)}%' : '-';

		return '''
----- INTERNET QUALITY -----
Ping: ${ping?.toStringAsFixed(2)} ms
Jitter: ${jitter?.toStringAsFixed(2)} ms
Ping success rate: $successPct
Download: ${download?.toStringAsFixed(2)} Mbps
Upload: ${upload?.toStringAsFixed(2)} Mbps
StartedAt: $startedAt
Duration: ${duration.inMilliseconds} ms
Endpoint: $endpoint
Success: $success
Error: ${error ?? "-"}
''';
	}
}
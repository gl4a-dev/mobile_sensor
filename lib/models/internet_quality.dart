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

	Map<String, dynamic> toMap() {
		return {
			'ping': ping,
			'jitter': jitter,
			'ping_success_rate': pingSuccessRate,
			'download_mbps': download,
			'upload_mbps': upload,
			'started_at': startedAt.toIso8601String(),
			'duration_ms': duration.inMilliseconds,
			'endpoint': endpoint,
			'success': success,
			'error': error,
		};
	}

	factory InternetQuality.fromMap(Map<String, dynamic> map) {
		return InternetQuality(
			ping: (map['ping'] as num?)?.toDouble(),
			jitter: (map['jitter'] as num?)?.toDouble(),
			pingSuccessRate: (map['ping_success_rate'] as num?)?.toDouble(),
			download: (map['download_mbps'] as num?)?.toDouble(),
			upload: (map['upload_mbps'] as num?)?.toDouble(),
			startedAt: DateTime.parse(map['started_at'] as String),
			duration: Duration(milliseconds: map['duration_ms'] as int),
			endpoint: map['endpoint'] as String,
			success: map['success'] as bool,
			error: map['error'] as String?,
		);
	}

	@override
	String toString() {
		final successPct = pingSuccessRate != null ? '${(pingSuccessRate! * 100).toStringAsFixed(0)}%' : '-';

		return 
'''
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
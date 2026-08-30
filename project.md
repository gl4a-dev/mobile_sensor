# Project Structure

```text
lib
├── data
│   └── local_measurement_storage.dart
├── models
│   ├── internet_quality.dart
│   ├── location.dart
│   ├── measurement.dart
│   ├── network_status.dart
│   ├── noise.dart
│   ├── wifi_list.dart
│   └── wifi_network.dart
├── screens
│   ├── dashboard_screen.dart
│   ├── history_screen.dart
│   └── measurement_screen.dart
├── services
│   ├── internet_quality_service.dart
│   ├── location_service.dart
│   ├── measurement_service.dart
│   ├── network_status_service.dart
│   ├── noise_service.dart
│   └── wifi_scan_service.dart
└── main.dart
```

# File Contents

## data\local_measurement_storage.dart

```dart
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/measurement.dart';

class LocalMeasurementStorage {
	static Database? _database;

	Future<Database> get database async {
		if (_database != null) return _database!;
		_database = await _initDB();
		return _database!;
	}

	Future<Database> _initDB() async {
		final dbPath = await getDatabasesPath();
		final path = join(dbPath, 'sensor_measurements.db');

		return await openDatabase(
			path,
			version: 1,
			onCreate: (db, version) async {
				await db.execute('''
					CREATE TABLE measurements (
						id TEXT PRIMARY KEY,
						payload TEXT NOT NULL,
						created_at TEXT NOT NULL
					)
				''');
			},
		);
	}

	Future<int> saveMeasurement(Measurement measurement) async {
		final db = await database;
		return await db.insert(
			'measurements',
			{
				'id': measurement.id,
				'payload': measurement.toJsonString(),
				'created_at': measurement.timestamp.toIso8601String(),
			},
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	Future<List<Map<String, dynamic>>> getMeasurementsAsJson() async {
		final db = await database;
		final rows = await db.query('measurements', orderBy: 'created_at DESC');

		return rows.map((row) {
			return jsonDecode(row['payload'] as String) as Map<String, dynamic>;
		}).toList();
	}

	Future<List<Measurement>> getMeasurements() async {
		final db = await database;
		final rows = await db.query('measurements', orderBy: 'created_at DESC');

		return rows.map((row) {
			return Measurement.fromJsonString(row['payload'] as String);
		}).toList();
	}

	Future<int> clearStorage() async {
		final db = await database;
		return await db.delete('measurements');
	}
}
```

## models\internet_quality.dart

```dart
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
```

## models\location.dart

```dart
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
```

## models\measurement.dart

```dart
import 'dart:convert';

import 'location.dart';
import 'internet_quality.dart';
import 'network_status.dart';
import 'wifi_list.dart';
import 'noise.dart';

class Measurement {
	final String id;
	final DateTime timestamp;

	final Location? location;
	final InternetQuality? internetQuality;
	final NetworkStatus? networkStatus;
	final WifiList? wifiList;
	final NoiseMeasurement? noiseMeasurement;

	const Measurement({
		required this.id,
		required this.timestamp,
		this.location,
		this.networkStatus,
		this.internetQuality,
		this.wifiList,
		this.noiseMeasurement,
	});

	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'timestamp': timestamp.toIso8601String(),
			'location': location?.toMap(),
			'internet_quality': internetQuality?.toMap(),
			'network_status': networkStatus?.toMap(),
			'wifi_list': wifiList?.toMapList(),
			'noise_measurement': noiseMeasurement?.toMap(),
		};
	}

	String toJsonString() => jsonEncode(toMap());

	factory Measurement.fromMap(Map<String, dynamic> map) {
		return Measurement(
		id: map['id'] as String,
		timestamp: DateTime.parse(map['timestamp'] as String),
		location: map['location'] != null
			? Location.fromMap(map['location'] as Map<String, dynamic>)
			: null,
		internetQuality: map['internet_quality'] != null
			? InternetQuality.fromMap(map['internet_quality'] as Map<String, dynamic>)
			: null,
		networkStatus: map['network_status'] != null
			? NetworkStatus.fromMap(map['network_status'] as Map<String, dynamic>)
			: null,
		wifiList: map['wifi_list'] != null
			? WifiList.fromMapList(map['wifi_list'] as List<dynamic>)
			: null,
		noiseMeasurement: map['noise_measurement'] != null
			? NoiseMeasurement.fromMap(map['noise_measurement'] as Map<String, dynamic>)
			: null,
		);
	}

	factory Measurement.fromJsonString(String source) =>
		Measurement.fromMap(jsonDecode(source) as Map<String, dynamic>);

	@override
	String toString() {
		return 
'''
------ MEASUREMENT ------
$id
$timestamp

${location.toString()}

${networkStatus.toString()}

${internetQuality.toString()}

${wifiList.toString()}

${noiseMeasurement.toString()}

''';
	}
}

```

## models\network_status.dart

```dart
class NetworkStatus {
    final String connectionType;

    final String? connectedSsid;
    final String? connectedBssid;

    final bool isMetered;
    final bool hasInternet;
    final bool isValidated;

    final String? mobileOperator;
    final String? mobileCountryCode;
    final String? mobileNetworkCode;

    const NetworkStatus({
        required this.connectionType,
        this.connectedSsid,
        this.connectedBssid,
        this.isMetered = false,
        this.hasInternet = false,
        this.isValidated = false,
        this.mobileOperator,
        this.mobileCountryCode,
        this.mobileNetworkCode,
    });

	Map<String, dynamic> toMap() {
		return {
			'connection_type': connectionType,
			'connected_ssid': connectedSsid,
			'connected_bssid': connectedBssid,
			'is_metered': isMetered,
			'has_internet': hasInternet,
			'is_validated': isValidated,
			'mobile_operator': mobileOperator,
			'mobile_country_code': mobileCountryCode,
			'mobile_network_code': mobileNetworkCode,
		};
	}

	factory NetworkStatus.fromMap(Map<String, dynamic> map) {
		return NetworkStatus(
			connectionType: map['connection_type'] as String,
			connectedSsid: map['connected_ssid'] as String?,
			connectedBssid: map['connected_bssid'] as String?,
			isMetered: map['is_metered'] as bool? ?? false,
			hasInternet: map['has_internet'] as bool? ?? false,
			isValidated: map['is_validated'] as bool? ?? false,
			mobileOperator: map['mobile_operator'] as String?,
			mobileCountryCode: map['mobile_country_code'] as String?,
			mobileNetworkCode: map['mobile_network_code'] as String?,
		);
	}

    @override
    String toString() {
        return 
'''
----- NETWORK STATUS -----
Type: $connectionType
SSID: ${connectedSsid ?? "-"}
BSSID: ${connectedBssid ?? "-"}
Metered Connection: $isMetered
Internet available: $hasInternet
Internet validated: $isValidated
Operator: ${mobileOperator ?? "-"}
MCC: ${mobileCountryCode ?? "-"}
MNC: ${mobileNetworkCode ?? "-"}
''';
    }
}
```

## models\noise.dart

```dart
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
```

## models\wifi_list.dart

```dart
import 'wifi_network.dart';

class WifiList {
	final List<WifiNetwork> networks;

	const WifiList([this.networks = const []]);

	List<Map<String, dynamic>> toMapList() {
		return networks.map((w) => w.toMap()).toList();
	}

	factory WifiList.fromMapList(List<dynamic> list) {
		return WifiList(
			list.map((item) => WifiNetwork.fromMap(item as Map<String, dynamic>)).toList(),
		);
	}

	@override
	String toString() {
		if (networks.isEmpty) {
			return 
'''
No network founded;
''';
		} else {
			return 
'''
----- WIFI LIST -----
${networks.map((w) => w.toString()).join('\n')}
''';
		}
	}
}

```

## models\wifi_network.dart

```dart
class WifiNetwork {
	final String ssid;
	final String bssid;
	final int rssi;

	WifiNetwork({
		required this.ssid,
		required this.bssid,
		required this.rssi,
	});

	Map<String, dynamic> toMap() {
		return {
			'ssid': ssid,
			'bssid': bssid,
			'rssi': rssi,
		};
	}

	factory WifiNetwork.fromMap(Map<String, dynamic> map) {
		return WifiNetwork(
			ssid: map['ssid'] as String,
			bssid: map['bssid'] as String,
			rssi: map['rssi'] as int,
		);
	}

	@override
	String toString() {
		return 'SSID: $ssid | BSSID: $bssid | RSSI: $rssi';
	}
}
```

## screens\dashboard_screen.dart

```dart
import 'package:flutter/material.dart';
import 'measurement_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // GlobalKey para invocar a recarga dos dados na HistoryScreen
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey<HistoryScreenState>();

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Se navegou para a aba de Histórico (index 1), força o recarregamento do SQLite
    if (index == 1) {
      _historyKey.currentState?.loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MeasurementScreen(),
          HistoryScreen(key: _historyKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFF58A6FF),
        unselectedItemColor: const Color(0xFF8B949E),
        selectedLabelStyle: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontFamily: 'monospace'),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'Run ()',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_object),
            label: 'Logs []',
          ),
        ],
      ),
    );
  }
}
```

## screens\history_screen.dart

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

import '../data/local_measurement_storage.dart';


class HistoryScreen extends StatefulWidget {
	const HistoryScreen({super.key});

	@override
	State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
	final LocalMeasurementStorage _storage = LocalMeasurementStorage();
	List<Map<String, dynamic>> _jsonVector = [];
	bool _isLoading = true;
	bool _showRawVector = false;

	@override
	void initState() {
		super.initState();
		loadHistory();
	}

	Future<void> loadHistory() async {
		setState(() => _isLoading = true);
		try {
			final data = await _storage.getMeasurementsAsJson();
			if (!mounted) return;
			setState(() {
				_jsonVector = data;
				_isLoading = false;
			});
		} catch (e) {
			if (!mounted) return;
			setState(() => _isLoading = false);
		}
	}

	Future<void> _clearHistory() async {
		await _storage.clearStorage();
		await loadHistory();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
		appBar: AppBar(
			title: Text('history.json [${_jsonVector.length}]'),
			actions: [
				IconButton(
					icon: Icon(_showRawVector ? Icons.list : Icons.code),
					tooltip: 'Alternar View RAW/Lista',
					onPressed: () => setState(() => _showRawVector = !_showRawVector),
				),
				IconButton(
					icon: const Icon(Icons.delete_outline, color: Color(0xFFF85149)),
					tooltip: 'Clear DB',
					onPressed: _jsonVector.isEmpty ? null : _clearHistory,
				),
			],
		),
		body: _isLoading
			? const Center(child: CircularProgressIndicator())
			: _jsonVector.isEmpty
				? const Center(
					child: Text(
						'// Nenhuma medição registrada.',
						style: TextStyle(fontFamily: 'monospace', color: Color(0xFF8B949E)),
					),
				)
				: RefreshIndicator(
					onRefresh: loadHistory,
					child: _showRawVector ? _buildRawVectorView() : _buildListView(),
				),
		);
	}

	Widget _buildRawVectorView() {
		final rawText = const JsonEncoder.withIndent('  ').convert(_jsonVector);
		return Padding(
			padding: const EdgeInsets.all(16.0),
			child: Container(
				width: double.infinity,
				padding: const EdgeInsets.all(12),
				decoration: BoxDecoration(
					color: const Color(0xFF010409),
					borderRadius: BorderRadius.circular(6),
					border: Border.all(color: const Color(0xFF30363D)),
				),
				child: SingleChildScrollView(
				physics: const AlwaysScrollableScrollPhysics(),
				child: SelectableText(
					rawText,
					style: const TextStyle(
						fontFamily: 'monospace',
						fontSize: 11,
						color: Color(0xFF79C0FF),
					),
				),
				),
			),
		);
	}

	Widget _buildListView() {
		return ListView.builder(
			physics: const AlwaysScrollableScrollPhysics(),
			padding: const EdgeInsets.all(16),
			itemCount: _jsonVector.length,
			itemBuilder: (context, index) {
				final item = _jsonVector[index];
				final id = item['id'] as String? ?? 'N/A';
				final timestamp = item['timestamp'] as String? ?? '';
				final wifiCount = (item['wifi_list'] as List?)?.length ?? 0;

				return Card(
					color: const Color(0xFF161B22),
					margin: const EdgeInsets.only(bottom: 12),
					shape: RoundedRectangleBorder(
						side: const BorderSide(color: Color(0xFF30363D)),
						borderRadius: BorderRadius.circular(6),
					),
					child: ExpansionTile(
						title: Text(
						'ID: $id',
						style: const TextStyle(
							fontFamily: 'monospace',
							fontSize: 13,
							fontWeight: FontWeight.bold,
							color: Color(0xFF58A6FF),
						),
						),
						subtitle: Text(
							'$timestamp | Wi-Fi: $wifiCount',
							style: const TextStyle(
								fontFamily: 'monospace',
								fontSize: 11,
								color: Color(0xFF8B949E),
							),
						),
						children: [
							Container(
								width: double.infinity,
								padding: const EdgeInsets.all(12),
								color: const Color(0xFF010409),
								child: SelectableText(
									const JsonEncoder.withIndent('  ').convert(item),
									style: const TextStyle(
										fontFamily: 'monospace',
										fontSize: 11,
										color: Color(0xFFA5D6FF),
									),
								),
							),
						],
					),
				);
			},
		);
	}
}
```

## screens\measurement_screen.dart

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

import '../data/local_measurement_storage.dart';
import '../services/location_service.dart';
import '../services/measurement_service.dart';
import '../services/noise_service.dart';
import '../services/internet_quality_service.dart';
import '../services/wifi_scan_service.dart';
import '../services/network_status_service.dart';
import '../models/measurement.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  late final MeasurementService _measurementService;
  final LocalMeasurementStorage _storage = LocalMeasurementStorage();

  bool _isLoading = false;
  Measurement? _lastMeasurement;
  String _rawJson = '// Aguardando execução do sensor...';

  @override
  void initState() {
    super.initState();
    _measurementService = MeasurementService(
      locationService: LocationService(),
      wifiScanService: WifiScanService(),
      noiseService: NoiseService(),
      networkStatusService: NetworkStatusService(),
      internetQualityService: InternetQualityService(),
    );
  }

  Future<void> _runMeasurement() async {
    setState(() {
      _isLoading = true;
      _rawJson = '// Executando coleta dos sensores...';
    });

    try {
      final measurement = await _measurementService.createMeasurement();
      await _storage.saveMeasurement(measurement);

      if (!mounted) return;

      setState(() {
        _lastMeasurement = measurement;
        _rawJson = const JsonEncoder.withIndent('  ').convert(measurement.toMap());
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rawJson = '// STDERR:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\$ ./sensor --record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runMeasurement,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'COLLETING DATA...' : 'EXECUTE MEASUREMENT'),
            ),
            const SizedBox(height: 16),
            if (_lastMeasurement != null) ...[
              _buildMetricsOverview(_lastMeasurement!),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF010409),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _rawJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF7EE787), // Verde Terminal
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsOverview(Measurement m) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('PING', '${m.internetQuality?.ping?.toStringAsFixed(0) ?? "-"} ms'),
          _buildStat('DOWN', '${m.internetQuality?.download?.toStringAsFixed(1) ?? "-"} Mbps'),
          _buildStat('NOISE', '${m.noiseMeasurement?.db.toStringAsFixed(1) ?? "-"} dB'),
          _buildStat('WIFI NETS', '${m.wifiList?.networks.length ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8B949E)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
```

## services\internet_quality_service.dart

```dart
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/internet_quality.dart';

class PingResult {
	final double averagePingMs;
	final double jitterMs;
	final double successRate;

	PingResult({
		required this.averagePingMs,
		required this.jitterMs,
		required this.successRate,
	});
}

class InternetQualityService {
	static const String _pingUrl = 'https://speed.cloudflare.com/__down?bytes=0';
	static const String _downloadUrl = 'https://speed.cloudflare.com/__down?bytes=1500000';
	static const String _uploadUrl = 'https://speed.cloudflare.com/__up';

	static const int _totalPings = 5;

	Future<InternetQuality> measureInternetQuality() async {
		final startedAt = DateTime.now();

		PingResult? pingMetrics;
		double? downloadMbps;
		double? uploadMbps;
		String? errorMessage;
		bool isSuccess = false;

		try {
			// 1. (5 Pings)
			pingMetrics = await _measurePingAndJitter();

			// 2. (~1.5 MB)
			downloadMbps = await _measureDownload();

			// 3. (~384 KB)
			uploadMbps = await _measureUpload();

			isSuccess = true;
		} catch (e) {
			errorMessage = e.toString();
		}

		final totalDuration = DateTime.now().difference(startedAt);

		return InternetQuality(
			ping: pingMetrics?.averagePingMs,
			jitter: pingMetrics?.jitterMs,
			pingSuccessRate: pingMetrics?.successRate,
			download: downloadMbps,
			upload: uploadMbps,
			startedAt: startedAt,
			duration: totalDuration,
			endpoint: 'speed.cloudflare.com',
			success: isSuccess,
			error: errorMessage,
		);
	}

	Future<PingResult> _measurePingAndJitter() async {
		final client = http.Client();
		final List<double> latencies = [];
		int successfulPings = 0;

		try {
			for (int i = 0; i < _totalPings; i++) {
				final stopwatch = Stopwatch()..start();
				try {
					final response = await client.get(Uri.parse(_pingUrl)).timeout(const Duration(seconds: 3));
					stopwatch.stop();

					if (response.statusCode == 200) {
						latencies.add(stopwatch.elapsedMilliseconds.toDouble());
						successfulPings++;
					}
				} catch (_) {
					// pass
				}

				if (i < _totalPings - 1) {
					await Future.delayed(const Duration(milliseconds: 100));
				}
			}
		} finally {
			client.close();
		}

		if (latencies.isEmpty) {
			throw Exception('Failed all ping tests (no connectivity)');
		}

		final double avgPing = latencies.reduce((a, b) => a + b) / latencies.length;

		double totalJitter = 0.0;
		if (latencies.length > 1) {
			for (int i = 0; i < latencies.length - 1; i++) {
				totalJitter += (latencies[i + 1] - latencies[i]).abs();
			}
			totalJitter /= (latencies.length - 1);
		}

		final double successRate = successfulPings / _totalPings;

		return PingResult(
			averagePingMs: avgPing,
			jitterMs: totalJitter,
			successRate: successRate,
		);
	}

	Future<double> _measureDownload() async {
		final stopwatch = Stopwatch()..start();
		final response = await http.get(Uri.parse(_downloadUrl)).timeout(const Duration(seconds: 10));
		stopwatch.stop();

		if (response.statusCode != 200) {
			throw Exception('Download Failure: Code ${response.statusCode}');
		}

		final bytesReceived = response.bodyBytes.length;
		final seconds = stopwatch.elapsedMilliseconds / 1000.0;

		if (seconds == 0) return 0.0;

		final megabits = (bytesReceived * 8) / 1000000.0;
		return megabits / seconds;
	}

	Future<double> _measureUpload() async {
		// Payload of ~384 KB (384 * 1024 bytes)
		final Uint8List payload = Uint8List(384 * 1024);

		final stopwatch = Stopwatch()..start();
		final response = await http.post(
			Uri.parse(_uploadUrl),
			body: payload,
		).timeout(const Duration(seconds: 10));

		stopwatch.stop();

		if (response.statusCode != 200) {
			throw Exception('UploadFailure: code ${response.statusCode}');
		}

		final bytesSent = payload.length;
		final seconds = stopwatch.elapsedMilliseconds / 1000.0;

		if (seconds == 0) return 0.0;

		final megabits = (bytesSent * 8) / 1000000.0;
		return megabits / seconds;
	}
}
```

## services\location_service.dart

```dart
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
```

## services\measurement_service.dart

```dart
import '../models/measurement.dart';

import 'internet_quality_service.dart';
import 'location_service.dart';
import 'network_status_service.dart';
import 'noise_service.dart';
import 'wifi_scan_service.dart';

class MeasurementService {
	final LocationService locationService;
	final WifiScanService wifiScanService;
	final NoiseService noiseService;
	final NetworkStatusService networkStatusService;
	final InternetQualityService internetQualityService;

	const MeasurementService({
		required this.locationService,
		required this.wifiScanService,
		required this.noiseService,
		required this.networkStatusService,
		required this.internetQualityService,
	});

	Future<Measurement> createMeasurement() async {
		final location = await locationService.getCurrentLocation();
		final wifiNetworks = await wifiScanService.scanNetworks();
		final noiseMeasurement = await noiseService.measureNoise();
		final networkStatus = await networkStatusService.getCurrentNetworkStatus();
		final internetQuality = await internetQualityService.measureInternetQuality();

		final measurement = Measurement(
		id: DateTime.now().microsecondsSinceEpoch.toString(),
		timestamp: DateTime.now(),

		location: location,
		noiseMeasurement: noiseMeasurement,
		internetQuality: internetQuality,
		networkStatus: networkStatus,
		wifiList: wifiNetworks,
		);

		return measurement;
	}
}
```

## services\network_status_service.dart

```dart
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
```

## services\noise_service.dart

```dart
import 'dart:math';
import 'package:record/record.dart';

import '../models/noise.dart';

class NoiseService {
	final AudioRecorder _recorder = AudioRecorder();

	Future<NoiseMeasurement> measureNoise() async {
		final hasPermission = await _recorder.hasPermission();

		if (!hasPermission) {
			throw Exception(
				'Permission to use the microphone denied.',
			);
		}

		const sampleRate = 16000;
		const channels = 1;

		final stream = await _recorder.startStream(
			const RecordConfig(
				encoder: AudioEncoder.pcm16bits,
				sampleRate: sampleRate,
				numChannels: channels,
			),
		);

		final samples = <int>[];

		final subscription = stream.listen((data) {
			for (int i = 0; i + 1 < data.length; i += 2) {
				final sample = data[i] | (data[i + 1] << 8);
				final signedSample = sample > 32767 ? sample - 65536 : sample;

				samples.add(signedSample);
			}
		});

		await Future.delayed(
			const Duration(seconds: 1),
		);

		await subscription.cancel();
		await _recorder.stop();

		if (samples.isEmpty) {
			throw Exception(
				'No audio sample obtained.',
			);
		}

		double sumSquares = 0;

		for (final sample in samples) {
			sumSquares += sample * sample;
		}

		final rms = sqrt(sumSquares / samples.length);

		if (rms <= 0) {
			return const NoiseMeasurement(
				rms: 0,
				db: 0,
			);
		}

		final normalizedRms = rms / 32768.0;
		final db = 20 * log(normalizedRms) / ln10;

		return NoiseMeasurement(
			rms: rms,
			db: db,
		);
	}

	Future<void> dispose() async {
		await _recorder.dispose();
	}
}
```

## services\wifi_scan_service.dart

```dart
import 'package:wifi_scan/wifi_scan.dart';
import '../models/wifi_network.dart';
import '../models/wifi_list.dart';

class WifiScanService {
	Future<WifiList> scanNetworks() async {
		final canScan = await WiFiScan.instance.canStartScan();

		if (canScan != CanStartScan.yes) {
			throw Exception('Não foi possível iniciar o scan: $canScan');
		}

		await WiFiScan.instance.startScan();
		final accessPoints = await WiFiScan.instance.getScannedResults();

		final networks = accessPoints.map((ap) {
			return WifiNetwork(
				ssid: ap.ssid,
				bssid: ap.bssid,
				rssi: ap.level,
			);
		}).toList();

		return WifiList(networks);
	}
}
```

## main.dart

```dart
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
	runApp(const MobileSensorApp());
}

class MobileSensorApp extends StatelessWidget {
	const MobileSensorApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			title: 'Sensor Dev Suite',
			theme: ThemeData.dark().copyWith(
				scaffoldBackgroundColor: const Color(0xFF0D1117),
				colorScheme: const ColorScheme.dark(
					primary: Color(0xFF58A6FF),
					surface: Color(0xFF161B22),
					onSurface: Color(0xFFC9D1D9),
				),
				appBarTheme: const AppBarTheme(
					backgroundColor: Color(0xFF161B22),
					elevation: 0,
					titleTextStyle: TextStyle(
						fontFamily: 'monospace',
						fontSize: 18,
						fontWeight: FontWeight.bold,
						color: Color(0xFF58A6FF),
					),
				),
				elevatedButtonTheme: ElevatedButtonThemeData(
					style: ElevatedButton.styleFrom(
						backgroundColor: const Color(0xFF238636),
						foregroundColor: Colors.white,
						textStyle: const TextStyle(
							fontFamily: 'monospace',
							fontWeight: FontWeight.bold,
						),
						padding: const EdgeInsets.symmetric(vertical: 16),
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(6),
						),
					),
				),
			),
			home: const DashboardScreen(),
		);
	}
}
```

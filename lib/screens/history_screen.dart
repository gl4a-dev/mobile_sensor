import 'dart:convert';
import 'package:flutter/material.dart';

import '../data/local_measurement_storage.dart';
import '../data/auth/auth_service.dart';


class HistoryScreen extends StatefulWidget {
	const HistoryScreen({super.key});

	@override
	State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
	final LocalMeasurementStorage _storage = LocalMeasurementStorage();
	final AuthService _authService = AuthService();

	List<Map<String, dynamic>> _jsonVector = [];
	bool _isLoading = true;
	bool _isSyncing = false;
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

	Future<void> _syncPendingMeasurements() async {
		setState(() => _isSyncing = true);

		try {
			final unsynced = await _storage.getUnsyncedMeasurementsRaw();

			if (unsynced.isEmpty) {
				if (mounted) {
					ScaffoldMessenger.of(context).showSnackBar(
						const SnackBar(
							content: Text('All the records are already synced.'),
						),
					);
				}
				return;
			}

			final success = await _authService.sendBatchMeasurements(unsynced);

			if (success) {
				final syncedIds = unsynced.map((e) => e['id'] as String).toList();
				await _storage.markAsSynced(syncedIds);

				if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
					content: Text('${syncedIds.length} registro(s) sincronizado(s) com sucesso!'),
					backgroundColor: const Color(0xFF238636),
					),
				);
				}

				await loadHistory();
			} else {
				throw Exception('O servidor retornou um erro ao processar o lote.');
			}
		} catch (e) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text('Falha na sincronização: ${e.toString()}'),
					backgroundColor: const Color(0xFFDA3633),
				),
				);
			}
		} finally {
			if (mounted) {
				setState(() => _isSyncing = false);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
		appBar: AppBar(
			title: Text('history.json [${_jsonVector.length}]'),
			actions: [
				_isSyncing
				? const Padding(
					padding: EdgeInsets.symmetric(horizontal: 12.0),
					child: Center(
						child: SizedBox(
							width: 18,
							height: 18,
							child: CircularProgressIndicator(
								strokeWidth: 2,
								color: Color(0xFF58A6FF),
							),
						),
					),
				)
				: IconButton(
					icon: const Icon(Icons.cloud_upload_outlined),
					tooltip: 'Sync Pending Records',
					onPressed: _syncPendingMeasurements,
				),
				IconButton(
					icon: Icon(_showRawVector ? Icons.list : Icons.code),
					tooltip: 'Toggle View RAW/List',
					onPressed: () => setState(() => _showRawVector = !_showRawVector),
				),
				IconButton(
					icon: const Icon(Icons.delete_outline, color: Color(0xFFF85149)),
					tooltip: 'Clear Local DB',
					onPressed: _jsonVector.isEmpty ? null : _clearHistory,
				),
			],
		),
		body: _isLoading
			? const Center(child: CircularProgressIndicator())
			: _jsonVector.isEmpty
			? const Center(
				child: Text(
					'// None measurement recorded.',
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
				final isSynced = item['is_sync'] as bool? ?? false;
				final syncLabel = isSynced ? 'SYNCED' : 'NOT SYNCED';

				return Card(
					color: const Color(0xFF161B22),
					margin: const EdgeInsets.only(bottom: 12),
					shape: RoundedRectangleBorder(
						side: const BorderSide(color: Color(0xFF30363D)),
						borderRadius: BorderRadius.circular(6),
					),
					child: ExpansionTile(
						title: Text(
							'ID: $id ($syncLabel)',
							style: TextStyle(
								fontFamily: 'monospace',
								fontSize: 13,
								fontWeight: FontWeight.bold,
								color: isSynced ? const Color(0xFF58A6FF) : const Color(0xFFD29922),
							),
							overflow: TextOverflow.ellipsis,
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
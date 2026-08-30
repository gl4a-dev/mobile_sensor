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
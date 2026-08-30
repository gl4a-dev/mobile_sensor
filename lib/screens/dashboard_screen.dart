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
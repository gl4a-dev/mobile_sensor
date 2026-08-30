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

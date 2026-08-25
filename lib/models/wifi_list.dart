import 'wifi_network.dart';

class WifiList {
	final List<WifiNetwork> networks;

	const WifiList([this.networks = const []]);

	@override
	String toString() {
		if (networks.isEmpty) {
			return '''
				No network founded;
			''';
		} else {
			return '''
----- WIFI LIST -----
${networks.map((w) => w.toString()).join('\n')}
''';
		}
	}
}

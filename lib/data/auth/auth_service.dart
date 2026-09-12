import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AuthService {
	final FirebaseAuth _auth = FirebaseAuth.instance;

	User? get currentUser => _auth.currentUser;

	Stream<User?> get authStateChanges => _auth.authStateChanges();

	Future<void> _verifyTokenWithBackend(String idToken) async {
		final backendUrl = dotenv.env['BACKEND_URL'] ?? 'https://your-backend.onrender.com';

		final response = await http.post(
			Uri.parse('$backendUrl/api/v1/auth/google'),
			headers: {'Content-Type': 'application/json'},
			body: jsonEncode({'id_token': idToken}),
		);

		if (response.statusCode != 200) {
			final errorData = jsonDecode(response.body);
			final String errorMessage = errorData['detail'] ?? 'Authorization error on the server.';
			throw Exception(errorMessage);
		}
	}

	Future<UserCredential?> signInWithGoogle() async {
		try {
			final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];

			if (serverClientId == null || serverClientId.isEmpty) {
				throw Exception("GOOGLE_SERVER_CLIENT_ID hasn't been set up in the .env file");
			}

			await GoogleSignIn.instance.initialize(
				serverClientId: serverClientId,
			);

			final googleUser = await GoogleSignIn.instance.authenticate();
			final googleAuth = googleUser.authentication;

			final String? idToken = googleAuth.idToken;

			if (idToken == null) {
				throw Exception('Failed to get the Google ID Token.');
			}

			await _verifyTokenWithBackend(idToken);
			// await Future.delayed(const Duration(seconds: 1));

			final OAuthCredential credential = GoogleAuthProvider.credential(
				idToken: idToken,
			);

			return await _auth.signInWithCredential(credential);

		} catch (e, stackTrace) {
			await signOut();

			print('--- ERROR DETAIS ---');
			print(e);
			print(stackTrace);
			print('---------------------------------------');

			if (e.toString().contains('Exception:')) rethrow;
			return null;
		}
	}

	Future<void> signOut() async {
		await GoogleSignIn.instance.signOut();
		await _auth.signOut();
	}

	Future<bool> sendBatchMeasurements(List<Map<String, dynamic>> payloadList) async {
		final user = _auth.currentUser;
		if (user == null) {
			throw Exception('User not authenticated.');
		}

		final idToken = await user.getIdToken();
		final backendUrl = dotenv.env['BACKEND_URL'] ?? 'https://your-backend.onrender.com';

		final response = await http.post(
			Uri.parse('$backendUrl/api/v1/measurements/batch'),
			headers: {
				'Content-Type': 'application/json',
				'Authorization': 'Bearer $idToken',
			},
			body: jsonEncode({'measurements': payloadList}),
		);

		return response.statusCode == 200 || response.statusCode == 201;
  	}
}
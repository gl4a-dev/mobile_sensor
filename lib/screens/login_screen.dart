import 'package:flutter/material.dart';
import '../data/auth/auth_service.dart';


class LoginScreen extends StatefulWidget {
	const LoginScreen({super.key});

	@override
	State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
	final AuthService _authService = AuthService();
	bool _isLoading = false;

	Future<void> _handleGoogleSignIn() async {
		setState(() => _isLoading = true);

		try {
			final userCredential = await _authService.signInWithGoogle();

			if (userCredential == null) {
				if (!mounted) return;
				ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
						content: Text(
							'Authentication canceled by the user.',
							style: TextStyle(fontFamily: 'monospace'),
						),
						backgroundColor: Color(0xFF30363D),
						behavior: SnackBarBehavior.floating,
					),
				);
			}

		} catch (e) {
			if (!mounted) return;

			final errorMessage = e.toString().replaceAll('Exception: ', '');

			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(
						errorMessage,
						style: const TextStyle(fontFamily: 'monospace'),
					),
					backgroundColor: const Color(0xFFDA3633), // Vermelho de erro estilo GitHub Dark
					behavior: SnackBarBehavior.floating,
				),
			);

		} finally {
			if (mounted) setState(() => _isLoading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFF0D1117), // Fundo escuro
			body: Center(
				child: Padding(
					padding: const EdgeInsets.all(24.0),
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							const Icon(Icons.sensors, size: 80, color: Color(0xFF58A6FF)),
							const SizedBox(height: 16),
							const Text(
								'Mobile Sensor',
								style: TextStyle(
									fontSize: 28,
									fontWeight: FontWeight.bold,
									color: Colors.white,
									fontFamily: 'monospace',
								),
							),
							const SizedBox(height: 8),
							const Text(
								'Restricted access for authorized users',
								style: TextStyle(
									color: Color(0xFF8B949E),
									fontFamily: 'monospace',
								),
							),
							const SizedBox(height: 48),

							_isLoading
							? const CircularProgressIndicator(color: Color(0xFF58A6FF))
							: ElevatedButton.icon(
								style: ElevatedButton.styleFrom(
									backgroundColor: const Color(0xFF21262D),
									foregroundColor: const Color(0xFF58A6FF),
									padding: const EdgeInsets.symmetric(
										horizontal: 24,
										vertical: 14,
									),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(8),
										side: const BorderSide(color: Color(0xFF30363D)),
									),
								),
								icon: const Icon(Icons.login),
								label: const Text(
									'Sign in with Google',
									style: TextStyle(
										fontFamily: 'monospace',
										fontWeight: FontWeight.bold,
									),
								),
								onPressed: _handleGoogleSignIn,
							),
						],
					),
				),
			),
		);
	}
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/server_config_service.dart';
import 'auth/login_screen.dart';
import 'home_shell.dart';
import 'server_setup_screen.dart';

/// Titik masuk app: cek apakah alamat server sudah pernah disimpan, lalu
/// cek apakah ada token tersimpan yang masih valid (`GET /auth/me`), baru
/// arahkan ke ServerSetup / Login / Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final serverConfig = context.read<ServerConfigService>();
    final auth = context.read<AuthService>();

    if (!serverConfig.isConfigured) {
      _replace(const ServerSetupScreen());
      return;
    }

    await auth.restoreSession();
    if (!mounted) return;
    _replace(auth.isAuthenticated ? const HomeShell() : const LoginScreen());
  }

  void _replace(Widget screen) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_filled, size: 56),
            SizedBox(height: 16),
            Text('Hestia', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/server_config_service.dart';
import 'auth/login_screen.dart';

/// Layar "Pengaturan server": user memasukkan alamat server Hestia
/// (mis. http://192.168.1.10:3000) di jaringan lokalnya, divalidasi lewat
/// GET /api/health sebelum disimpan.
class ServerSetupScreen extends StatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _testing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = context.read<ServerConfigService>().baseUrl;
    if (current != null) _controller.text = current;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _testing = true;
      _error = null;
    });

    final serverConfig = context.read<ServerConfigService>();
    final ok = await serverConfig.testConnection(_controller.text);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _testing = false;
        _error = 'Tidak dapat terhubung. Periksa alamat & pastikan server Hestia sedang berjalan.';
      });
      return;
    }

    await serverConfig.setBaseUrl(_controller.text);
    if (!mounted) return;

    // Token lama (bila ada) terikat ke server sebelumnya — tidak berlaku di server baru.
    final auth = context.read<AuthService>();
    if (auth.isAuthenticated) {
      await auth.logout();
    }
    if (!mounted) return;

    setState(() => _testing = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hubungkan ke Server')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Masukkan alamat server Hestia di jaringanmu.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Alamat server',
                  hintText: 'http://192.168.1.10:3000',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Alamat server wajib diisi.';
                  final uri = Uri.tryParse(v);
                  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                    return 'Alamat tidak valid (contoh: http://192.168.1.10:3000).';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _testing ? null : _submit,
                child: _testing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tes Koneksi & Lanjutkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

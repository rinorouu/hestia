import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/server_config_service.dart';
import '../auth/login_screen.dart';
import '../server_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu perlu login lagi untuk mengakses Hestia.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final serverConfig = context.watch<ServerConfigService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(user.nameOrEmail),
              subtitle: Text(user.email),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Alamat server'),
            subtitle: Text(serverConfig.baseUrl ?? '-'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServerSetupScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Keluar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}

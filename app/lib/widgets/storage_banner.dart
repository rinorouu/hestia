import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_status_service.dart';

/// Banner persisten yang muncul saat HDD eksternal server tidak terdeteksi
/// (`GET /storage/status` -> `available: false`). Lihat docs/ARCHITECTURE.md
/// bagian HDD Detection.
class StorageBanner extends StatelessWidget {
  const StorageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageStatusService>();
    final status = storage.status;
    if (status == null || status.available) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.sd_card_alert_outlined, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Media penyimpanan tidak tersedia. Upload dinonaktifkan sampai HDD terdeteksi kembali.',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.onErrorContainer),
                tooltip: 'Cek ulang',
                onPressed: storage.loading ? null : storage.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

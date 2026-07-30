import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/history_item.dart';
import '../../services/history_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_error_view.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<HistoryItem>> _load() => context.read<HistoryService>().list();

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Upload')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HistoryItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              final message = error is ApiException ? error.message : 'Gagal memuat riwayat.';
              return ListView(children: [ErrorView(message: message, onRetry: _refresh)]);
            }
            final items = snapshot.data ?? const <HistoryItem>[];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  EmptyView(message: 'Belum ada riwayat upload.', icon: Icons.history),
                ],
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(
                    item.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    color: item.isSuccess ? Colors.green : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(item.isSuccess ? 'Berhasil' : 'Gagal'),
                  subtitle: item.message != null ? Text(item.message!) : null,
                  trailing: Text(
                    formatDateTime(item.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

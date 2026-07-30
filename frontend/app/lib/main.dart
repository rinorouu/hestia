import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/file_service.dart';
import 'services/history_service.dart';
import 'services/server_config_service.dart';
import 'services/storage_status_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final serverConfigService = ServerConfigService();
  await serverConfigService.load();

  final authService = AuthService(serverConfig: serverConfigService);
  final storageStatusService = StorageStatusService(
    serverConfig: serverConfigService,
    authService: authService,
  );
  final fileService = FileService(serverConfig: serverConfigService, authService: authService);
  final historyService = HistoryService(serverConfig: serverConfigService, authService: authService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: serverConfigService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: storageStatusService),
        Provider.value(value: fileService),
        Provider.value(value: historyService),
      ],
      child: const HestiaApp(),
    ),
  );
}

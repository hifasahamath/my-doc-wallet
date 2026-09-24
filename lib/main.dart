import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/app.dart';
import 'package:my_doc_wallet/data/repositories/category_repository.dart';
import 'package:my_doc_wallet/data/repositories/document_repository.dart';
import 'package:my_doc_wallet/data/repositories/document_set_repository.dart';
import 'package:my_doc_wallet/services/document_service.dart';
import 'package:my_doc_wallet/services/export_service.dart';
import 'package:my_doc_wallet/services/file_storage_service.dart';
import 'package:my_doc_wallet/services/import_service.dart';
import 'package:my_doc_wallet/services/notification_service.dart';
import 'package:my_doc_wallet/services/ocr_service.dart';
import 'package:my_doc_wallet/services/security_service.dart';
import 'package:my_doc_wallet/providers/auth_provider.dart';
import 'package:my_doc_wallet/providers/category_provider.dart';
import 'package:my_doc_wallet/providers/dashboard_provider.dart';
import 'package:my_doc_wallet/providers/document_provider.dart';
import 'package:my_doc_wallet/providers/document_set_provider.dart';
import 'package:my_doc_wallet/providers/search_provider.dart';
import 'package:my_doc_wallet/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services
  final securityService = SecurityService();
  final fileStorageService = FileStorageService();
  final notificationService = NotificationService();
  await notificationService.initialize();
  final exportService = ExportService(fileStorageService);
  final ocrService = OcrService(fileStorageService);
  final importService = ImportService();

  // Initialize Repositories
  final docRepo = DocumentRepository();
  final catRepo = CategoryRepository();
  final setRepo = DocumentSetRepository();

  final documentService = DocumentService(docRepo, fileStorageService);

  // Initialize Auth & Settings explicitly before app start
  final authProvider = AuthProvider(securityService, fileStorageService);
  await authProvider.initialize();

  final settingsProvider = SettingsProvider(securityService);
  await settingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider.value(value: fileStorageService),
        Provider.value(value: exportService),
        Provider.value(value: ocrService),
        Provider.value(value: documentService),
        Provider.value(value: importService),
        
        // Repositories
        Provider.value(value: docRepo),
        Provider.value(value: catRepo),
        Provider.value(value: setRepo),
        
        // Providers (State)
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(
          create: (_) => DocumentProvider(docRepo, documentService, notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(catRepo, docRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(docRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(docRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DocumentSetProvider(setRepo),
        ),
      ],
      child: const MyDocWalletApp(),
    ),
  );
}

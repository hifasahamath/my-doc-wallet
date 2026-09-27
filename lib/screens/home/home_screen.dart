import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/utils/file_utils.dart';
import 'package:my_doc_wallet/providers/auth_provider.dart';

import 'package:my_doc_wallet/providers/dashboard_provider.dart';
import 'package:my_doc_wallet/providers/document_provider.dart';
import 'package:my_doc_wallet/screens/home/dashboard_tab.dart';
import 'package:my_doc_wallet/screens/documents/documents_list_screen.dart';
import 'package:my_doc_wallet/screens/categories/categories_screen.dart';
import 'package:my_doc_wallet/screens/settings/settings_screen.dart';
import 'package:my_doc_wallet/services/import_service.dart';
import 'package:my_doc_wallet/widgets/import_metadata_dialog.dart';

/// Main shell with bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _pages = const [
    DashboardTab(),
    DocumentsListScreen(),
    CategoriesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = context.read<AuthProvider>();
    if (state == AppLifecycleState.resumed) {
      auth.shouldAutoLock().then((should) {
        if (should && mounted) {
          auth.lock();
        } else {
          auth.recordActivity();
        }
      });
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.inactive) {
      auth.recordActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => context.read<AuthProvider>().recordActivity(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Documents'),
            NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Categories'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddOptions(context),
          label: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Import', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.add, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: const Icon(Icons.document_scanner_outlined, size: 32),
                title: const Text('Scan Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                subtitle: const Text('Use camera to scan physical documents', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleScan(context, categoryId: null);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: const Icon(Icons.file_upload_outlined, size: 32),
                title: const Text('Import File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                subtitle: const Text('Import PDF or image from your device', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleImport(context, categoryId: null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Import a file directly — no form. The first available category is used
  /// when no [categoryId] is provided.
  Future<void> _handleImport(BuildContext context, {String? categoryId}) async {
    final importService = context.read<ImportService>();
    final docProvider = context.read<DocumentProvider>();
    final dashProvider = context.read<DashboardProvider>();

    try {
      final path = await importService.pickFile();
      if (path == null) return; // User cancelled

      if (!context.mounted) return;

      // Determine category (null means Uncategorized)
      final effectiveCategoryId = categoryId;
      final generatedTitle = FileUtils.titleFromFilename(path);

      final metadata = await ImportMetadataDialog.show(
        context,
        initialTitle: generatedTitle,
        initialCategoryId: effectiveCategoryId,
      );
      if (metadata == null) return; // User cancelled dialog

      if (!context.mounted) return;

      final title = metadata['title'] as String? ?? generatedTitle;
      final selectedCategory = metadata['categoryId'] as String? ?? 'uncategorized';
      final expiryDate = metadata['expiryDate'] as DateTime?;

      // Show a brief loading indicator
      _showLoading(context, 'Importing document...');

      final newDoc = await docProvider.importFile(
        sourcePath: path,
        name: title,
        categoryId: selectedCategory,
      );
      
      if (expiryDate != null) {
        await docProvider.updateDocument(newDoc.copyWith(expiryDate: expiryDate));
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        dashProvider.loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$title" imported successfully')),
        );
      }
    } on ImportException catch (e) {
      if (context.mounted) {
        // Dismiss loading if it was shown
        Navigator.of(context, rootNavigator: true).pop();
        if (e.isPermanentlyDenied) {
          _showPermissionDeniedDialog(context, e.message);
        } else {
          _showError(context, e.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Try to dismiss loading
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        _showError(context, 'Failed to import document: $e');
      }
    }
  }

  /// Scan a document directly — no form.
  Future<void> _handleScan(BuildContext context, {String? categoryId}) async {
    final importService = context.read<ImportService>();
    final docProvider = context.read<DocumentProvider>();
    final dashProvider = context.read<DashboardProvider>();

    try {
      final paths = await importService.scanDocuments();
      if (paths == null || paths.isEmpty) return; // User cancelled

      if (!context.mounted) return;

      // Determine category (null means Uncategorized)
      final effectiveCategoryId = categoryId;
      final metadata = await ImportMetadataDialog.show(
        context,
        initialTitle: 'Scanned Document',
        initialCategoryId: effectiveCategoryId,
      );
      if (metadata == null) return; // User cancelled dialog

      if (!context.mounted) return;

      final title = metadata['title'] as String? ?? 'Scanned Document';
      final selectedCategory = metadata['categoryId'] as String? ?? 'uncategorized';
      final expiryDate = metadata['expiryDate'] as DateTime?;

      // Show a brief loading indicator
      _showLoading(context, 'Saving scanned document...');

      final newDoc = await docProvider.createFromScan(
        imagePaths: paths,
        name: title,
        categoryId: selectedCategory,
      );

      if (expiryDate != null) {
        await docProvider.updateDocument(newDoc.copyWith(expiryDate: expiryDate));
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        dashProvider.loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scanned document saved successfully')),
        );
      }
    } on ImportException catch (e) {
      if (context.mounted) {
        if (e.isPermanentlyDenied) {
          _showPermissionDeniedDialog(context, e.message);
        } else {
          _showError(context, e.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        _showError(context, 'Failed to scan document: $e');
      }
    }
  }

  void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

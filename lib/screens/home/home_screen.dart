import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/providers/auth_provider.dart';
import 'package:my_doc_wallet/screens/home/dashboard_tab.dart';
import 'package:my_doc_wallet/screens/documents/documents_list_screen.dart';
import 'package:my_doc_wallet/screens/categories/categories_screen.dart';
import 'package:my_doc_wallet/screens/settings/settings_screen.dart';
import 'package:my_doc_wallet/services/import_service.dart';

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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddOptions(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('Scan Document'),
              subtitle: const Text('Use camera to scan physical documents'),
              onTap: () async {
                Navigator.pop(context);
                final service = context.read<ImportService>();
                final paths = await service.scanDocuments();
                if (paths != null && paths.isNotEmpty && context.mounted) {
                  context.push('/add-document-scan', extra: paths);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import File'),
              subtitle: const Text('Import PDF or image from your device'),
              onTap: () async {
                Navigator.pop(context);
                final service = context.read<ImportService>();
                final path = await service.pickFile();
                if (path != null && context.mounted) {
                  context.push('/add-document-file', extra: path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

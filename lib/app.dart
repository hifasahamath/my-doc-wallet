import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/theme/app_theme.dart';
import 'package:my_doc_wallet/providers/auth_provider.dart';
import 'package:my_doc_wallet/providers/settings_provider.dart';
import 'package:my_doc_wallet/screens/auth/lock_screen.dart';
import 'package:my_doc_wallet/screens/auth/setup_pin_screen.dart';
import 'package:my_doc_wallet/screens/documents/status_documents_screen.dart';
import 'package:my_doc_wallet/screens/home/home_screen.dart';
import 'package:my_doc_wallet/screens/documents/document_detail_screen.dart';
import 'package:my_doc_wallet/screens/documents/add_edit_document_screen.dart';
import 'package:my_doc_wallet/screens/categories/category_documents_screen.dart';
import 'package:my_doc_wallet/screens/search/search_screen.dart';
import 'package:my_doc_wallet/screens/settings/about_screen.dart';
import 'package:my_doc_wallet/screens/settings/change_pin_screen.dart';

/// Root application widget.
///
/// The [GoRouter] is created once and cached so that theme changes (which
/// trigger a rebuild of [Consumer]) do NOT recreate the router and therefore
/// do NOT reset the current navigation stack back to '/'.
class MyDocWalletApp extends StatefulWidget {
  const MyDocWalletApp({super.key});

  @override
  State<MyDocWalletApp> createState() => _MyDocWalletAppState();
}

class _MyDocWalletAppState extends State<MyDocWalletApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isSetupComplete = auth.isSetupComplete;
        final isLocked = auth.isLocked;

        if (!isSetupComplete) {
          return '/setup';
        }
        if (isLocked) {
          return '/lock';
        }

        // If going to setup or lock but shouldn't be, redirect home
        if (state.matchedLocation == '/setup' ||
            state.matchedLocation == '/lock') {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/setup',
          builder: (context, state) => const SetupPinScreen(),
        ),
        GoRoute(
          path: '/lock',
          builder: (context, state) => const LockScreen(),
        ),
        GoRoute(
          path: '/edit-document/:id',
          builder: (context, state) =>
              AddEditDocumentScreen(documentId: state.pathParameters['id']),
        ),
        GoRoute(
          path: '/category/:id',
          builder: (context, state) => CategoryDocumentsScreen(
            categoryId: state.pathParameters['id']!,
            categoryName: (state.extra as String?) ?? 'Category',
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/document/:id',
          builder: (context, state) =>
              DocumentDetailScreen(documentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/status/:status',
          builder: (context, state) =>
              StatusDocumentsScreen(status: state.pathParameters['status']!),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: '/change-pin',
          builder: (context, state) => const ChangePinScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only consume SettingsProvider for theme — the router is stable.
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, auth, settings, child) {
        // Refresh redirect logic when auth state changes.
        _router.refresh();
        return MaterialApp.router(
          title: 'MyDoc Wallet',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

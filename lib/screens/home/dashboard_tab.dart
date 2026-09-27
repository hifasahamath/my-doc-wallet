import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/theme/app_theme.dart';
import 'package:my_doc_wallet/providers/dashboard_provider.dart';
import 'package:my_doc_wallet/widgets/document_card.dart';
import 'package:my_doc_wallet/widgets/empty_state.dart';
import 'package:my_doc_wallet/widgets/stat_card.dart';
import 'package:my_doc_wallet/providers/document_provider.dart';

/// Dashboard tab showing stats, favorites, and expiring-soon documents.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('MyDoc Wallet',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboard.loadDashboard(),
        child: dashboard.isLoading && dashboard.totalCount == 0
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  // Stats grid — responsive
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 600 ? 4 : 2;
                        final aspectRatio = width > 600 ? 1.5 : (width < 340 ? 1.2 : 1.4);
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: aspectRatio,
                          children: [
                            StatCard(
                              label: 'Total',
                              count: dashboard.totalCount,
                              icon: Icons.folder,
                              color: theme.colorScheme.primary,
                            ),
                            StatCard(
                              label: 'Active',
                              count: dashboard.activeCount,
                              icon: Icons.check_circle,
                              color: AppTheme.activeColor,
                            ),
                            StatCard(
                              label: 'Expiring Soon',
                              count: dashboard.expiringCount,
                              icon: Icons.schedule,
                              color: AppTheme.expiringColor,
                            ),
                            StatCard(
                              label: 'Expired',
                              count: dashboard.expiredCount,
                              icon: Icons.warning_amber,
                              color: AppTheme.expiredColor,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Favorites
                  if (dashboard.favorites.isNotEmpty) ...[
                    _sectionHeader(theme, 'Favorites', Icons.star),
                    ...dashboard.favorites.map((doc) => DocumentCard(
                          document: doc,
                          onTap: () => context.push('/document/${doc.id}'),
                          onFavoriteTap: () =>
                              context.read<DocumentProvider>().toggleFavorite(doc.id, !doc.isFavorite).then((_) => dashboard.loadDashboard()),
                        )),
                  ],

                  // Expiring soon
                  if (dashboard.expiringSoon.isNotEmpty) ...[
                    _sectionHeader(theme, 'Expiring Soon', Icons.schedule),
                    ...dashboard.expiringSoon.map((doc) => DocumentCard(
                          document: doc,
                          onTap: () => context.push('/document/${doc.id}'),
                          onFavoriteTap: () =>
                              context.read<DocumentProvider>().toggleFavorite(doc.id, !doc.isFavorite).then((_) => dashboard.loadDashboard()),
                        )),
                  ],

                  if (dashboard.totalCount == 0)
                    const EmptyState(
                      icon: Icons.folder_open,
                      title: 'No documents yet',
                      subtitle: 'Tap + to add your first document',
                    ),
                ],
              ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

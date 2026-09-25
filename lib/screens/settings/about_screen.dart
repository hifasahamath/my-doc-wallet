import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';

/// About and developer info screen with clickable contact links.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'Version ${info.version} (Build ${info.buildNumber})';
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About MyDoc Wallet'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App info
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/branding/mydoc_wallet_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.shield, size: 48, color: theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _version,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          
          const Divider(),
          const SizedBox(height: 16),
          
          // Developer info
          Text(
            'Developer',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
            ),
            title: const Text(
              AppConstants.developerName,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(AppConstants.developerRole),
          ),
          const SizedBox(height: 8),
          
          // ── Clickable contact links ─────────────────────────────────
          _DeveloperLink(
            icon: Icons.code,
            label: AppConstants.developerGithub,
            url: AppConstants.developerGithubUrl,
            onTap: () => _launchUrl(AppConstants.developerGithubUrl),
          ),
          _DeveloperLink(
            icon: Icons.language,
            label: AppConstants.developerWebsite,
            url: AppConstants.developerWebsiteUrl,
            onTap: () => _launchUrl(AppConstants.developerWebsiteUrl),
          ),
          _DeveloperLink(
            icon: Icons.chat,
            label: AppConstants.developerWhatsApp,
            url: AppConstants.developerWhatsAppUrl,
            onTap: () => _launchUrl(AppConstants.developerWhatsAppUrl),
          ),
        ],
      ),
    );
  }
}

/// A single developer contact link with icon, text, and tap behavior.
class _DeveloperLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final VoidCallback onTap;

  const _DeveloperLink({
    required this.icon,
    required this.label,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

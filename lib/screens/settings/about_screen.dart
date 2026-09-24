import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';

/// About and developer info screen.
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
            title: const Text(AppConstants.developerName),
            subtitle: const Text(AppConstants.developerRole),
          ),
          const SizedBox(height: 8),
          
          // Links
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: const Text(AppConstants.developerWebsite),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl(AppConstants.developerWebsiteUrl),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.code),
            title: const Text(AppConstants.developerGithub),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl(AppConstants.developerGithubUrl),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.chat),
            title: const Text(AppConstants.developerWhatsApp),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl(AppConstants.developerWhatsAppUrl),
          ),
        ],
      ),
    );
  }
}

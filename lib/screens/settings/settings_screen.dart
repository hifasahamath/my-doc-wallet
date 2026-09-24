import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/providers/auth_provider.dart';
import 'package:my_doc_wallet/providers/settings_provider.dart';

/// Settings screen for theme, security, and app preferences.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // Security Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Security', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/change-pin');
            },
          ),
          if (auth.isBiometricAvailable)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Unlock'),
              value: auth.isBiometricEnabled,
              onChanged: (val) => auth.toggleBiometric(val),
            ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Auto-lock timeout'),
            subtitle: Text(_formatAutoLock(settings.autoLockSeconds)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAutoLockDialog(context, settings);
            },
          ),
          
          const Divider(),
          
          // Appearance Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Appearance', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_formatTheme(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeDialog(context, settings);
            },
          ),
          
          const Divider(),
          
          // About Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('About', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About MyDoc Wallet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/about');
            },
          ),
        ],
      ),
    );
  }

  String _formatAutoLock(int seconds) {
    if (seconds < 0) return 'Never';
    if (seconds == 0) return 'Immediately';
    if (seconds < 60) return '$seconds seconds';
    if (seconds == 60) return '1 minute';
    return '${seconds ~/ 60} minutes';
  }

  void _showAutoLockDialog(BuildContext context, SettingsProvider settings) {
    final options = {
      0: 'Immediately',
      30: '30 seconds',
      60: '1 minute',
      300: '5 minutes',
      -1: 'Never',
    };
    
    showDialog(
      context: context,
      builder: (dialogContext) => _AutoLockDialog(
        options: options,
        currentValue: settings.autoLockSeconds,
        onSelected: (val) {
          settings.setAutoLockSeconds(val);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  String _formatTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System Default';
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ThemeDialog(
        currentMode: settings.themeMode,
        onSelected: (mode) {
          settings.setThemeMode(mode);
          Navigator.pop(dialogContext);
        },
        formatTheme: _formatTheme,
      ),
    );
  }
}

/// Stateful dialog for auto-lock selection using RadioGroup.
class _AutoLockDialog extends StatefulWidget {
  final Map<int, String> options;
  final int currentValue;
  final ValueChanged<int> onSelected;

  const _AutoLockDialog({
    required this.options,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<_AutoLockDialog> createState() => _AutoLockDialogState();
}

class _AutoLockDialogState extends State<_AutoLockDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Auto-lock timeout'),
      content: RadioGroup<int>(
        groupValue: _selected,
        onChanged: (val) {
          if (val != null) {
            widget.onSelected(val);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.options.entries.map((e) {
            return RadioListTile<int>(
              title: Text(e.value),
              value: e.key,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Stateful dialog for theme selection using RadioGroup.
class _ThemeDialog extends StatefulWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onSelected;
  final String Function(ThemeMode) formatTheme;

  const _ThemeDialog({
    required this.currentMode,
    required this.onSelected,
    required this.formatTheme,
  });

  @override
  State<_ThemeDialog> createState() => _ThemeDialogState();
}

class _ThemeDialogState extends State<_ThemeDialog> {
  late ThemeMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Theme'),
      content: RadioGroup<ThemeMode>(
        groupValue: _selected,
        onChanged: (val) {
          if (val != null) {
            widget.onSelected(val);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(widget.formatTheme(mode)),
              value: mode,
            );
          }).toList(),
        ),
      ),
    );
  }
}

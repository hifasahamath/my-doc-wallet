import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/providers/auth_provider.dart';

/// PIN entry lock screen with biometric option.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final auth = context.read<AuthProvider>();
    if (auth.isBiometricEnabled && auth.isBiometricAvailable) {
      setState(() => _loading = true);
      await auth.authenticateWithBiometric();
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDigit(int digit) {
    if (_pin.length >= AppConstants.pinLength) return;
    setState(() {
      _pin += digit.toString();
      _error = null;
    });
    if (_pin.length == AppConstants.pinLength) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final success = await context.read<AuthProvider>().verifyPin(_pin);
    if (!success && mounted) {
      setState(() {
        _pin = '';
        _error = 'Incorrect PIN';
        _loading = false;
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('MyDoc Wallet', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Enter your PIN', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(AppConstants.pinLength, (i) {
                final filled = i < _pin.length;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? theme.colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: _error != null
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 14)),
            ],
            const Spacer(flex: 1),
            // Numpad
            _buildNumpad(theme),
            const SizedBox(height: 16),
            // Biometric button
            if (auth.isBiometricEnabled && auth.isBiometricAvailable)
              TextButton.icon(
                onPressed: _loading ? null : _tryBiometric,
                icon: const Icon(Icons.fingerprint, size: 28),
                label: const Text('Use Biometric'),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 0; col < 3; col++)
                  _buildNumpadButton(row, col, theme),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(int row, int col, ThemeData theme) {
    if (row < 3) {
      final digit = row * 3 + col + 1;
      return _digitButton(digit, theme);
    }
    // Last row: empty, 0, backspace
    if (col == 0) return const SizedBox(width: 72, height: 60);
    if (col == 1) return _digitButton(0, theme);
    return SizedBox(
      width: 72,
      height: 60,
      child: IconButton(
        onPressed: _onBackspace,
        icon: Icon(Icons.backspace_outlined, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _digitButton(int digit, ThemeData theme) {
    return SizedBox(
      width: 72,
      height: 60,
      child: TextButton(
        onPressed: _loading ? null : () => _onDigit(digit),
        style: TextButton.styleFrom(shape: const CircleBorder()),
        child: Text(
          '$digit',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

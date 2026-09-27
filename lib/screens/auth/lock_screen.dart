import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/providers/auth_provider.dart';
import 'package:my_doc_wallet/widgets/numpad.dart';

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
      final success = await auth.authenticateWithBiometric();
      if (mounted) {
        setState(() => _loading = false);
        if (!success) {
          // Only show error if the user didn't cancel — a failed attempt
          // is worth mentioning so they know to retry or use PIN.
          setState(() => _error = 'Biometric authentication failed. Use PIN.');
        }
      }
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
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
    // Scale factor for small screens (baseline 375dp width)
    final scaleFactor = (screenWidth / 375).clamp(0.75, 1.3);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 580;
            return SingleChildScrollView(
              physics: isCompact ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: isCompact ? 24 : screenHeight * 0.08),
                      Icon(Icons.lock_outline, size: 48 * scaleFactor, color: theme.colorScheme.primary),
                      SizedBox(height: 12 * scaleFactor),
                      Text('MyDoc Wallet', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Enter your PIN', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      SizedBox(height: 24 * scaleFactor),
                      // PIN dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(AppConstants.pinLength, (i) {
                          final filled = i < _pin.length;
                          final dotSize = 14.0 * scaleFactor;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: dotSize,
                            height: dotSize,
                            margin: EdgeInsets.symmetric(horizontal: 7 * scaleFactor),
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
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Numpad
                      Numpad(
                        onDigit: _onDigit,
                        onBackspace: _onBackspace,
                        enabled: !_loading,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      // Biometric button
                      if (auth.isBiometricEnabled && auth.isBiometricAvailable)
                        TextButton.icon(
                          onPressed: _loading ? null : _tryBiometric,
                          icon: Icon(Icons.fingerprint, size: 26 * scaleFactor),
                          label: const Text('Use Biometric'),
                        ),
                      SizedBox(height: isCompact ? 16 : 28),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

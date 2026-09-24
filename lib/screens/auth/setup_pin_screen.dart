import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/providers/auth_provider.dart';

/// First-time PIN setup screen.
class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  String _pin = '';
  String? _firstPin;
  bool _isConfirming = false;
  String? _error;

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
    if (!_isConfirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
      return;
    }

    if (_pin != _firstPin) {
      setState(() {
        _pin = '';
        _error = 'PINs do not match. Try again.';
        _isConfirming = false;
        _firstPin = null;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    await context.read<AuthProvider>().setupPin(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(Icons.shield_outlined, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Set Up Your PIN', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _isConfirming ? 'Confirm your PIN' : 'Create a ${AppConstants.pinLength}-digit PIN',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
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
                      color: _error != null ? theme.colorScheme.error : theme.colorScheme.primary,
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
            _buildNumpad(theme),
            const SizedBox(height: 48),
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
        onPressed: () => _onDigit(digit),
        style: TextButton.styleFrom(shape: const CircleBorder()),
        child: Text('$digit', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500)),
      ),
    );
  }
}

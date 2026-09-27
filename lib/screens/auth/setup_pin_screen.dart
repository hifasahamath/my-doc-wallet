import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/providers/auth_provider.dart';
import 'package:my_doc_wallet/widgets/numpad.dart';

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
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
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
                      Icon(Icons.shield_outlined, size: 48 * scaleFactor, color: theme.colorScheme.primary),
                      SizedBox(height: 12 * scaleFactor),
                      Text('Set Up Your PIN', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        _isConfirming ? 'Confirm your PIN' : 'Create a ${AppConstants.pinLength}-digit PIN',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      SizedBox(height: 24 * scaleFactor),
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
                                color: _error != null ? theme.colorScheme.error : theme.colorScheme.primary,
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
                      _buildNumpad(theme, scaleFactor),
                      SizedBox(height: isCompact ? 24 : 40),
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

  Widget _buildNumpad(ThemeData theme, double scaleFactor) {
    return Numpad(
      onDigit: _onDigit,
      onBackspace: _onBackspace,
      scaleFactor: scaleFactor,
    );
  }
}

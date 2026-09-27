import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:my_doc_wallet/core/constants/app_constants.dart';
import 'package:my_doc_wallet/providers/auth_provider.dart';
import 'package:my_doc_wallet/widgets/numpad.dart';

/// Screen to change the user's PIN.
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String _pin = '';
  String? _oldPin;
  String? _newPin;
  
  // 0 = entering old PIN, 1 = entering new PIN, 2 = confirming new PIN
  int _step = 0;
  String? _error;
  bool _loading = false;

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
    final auth = context.read<AuthProvider>();
    
    if (_step == 0) {
      // Verify old PIN
      setState(() => _loading = true);
      final isValid = await auth.verifyPin(_pin);
      if (isValid) {
        setState(() {
          _oldPin = _pin;
          _pin = '';
          _step = 1;
          _loading = false;
        });
      } else {
        setState(() {
          _pin = '';
          _error = 'Incorrect current PIN';
          _loading = false;
        });
        HapticFeedback.heavyImpact();
      }
    } else if (_step == 1) {
      // Set new PIN
      setState(() {
        _newPin = _pin;
        _pin = '';
        _step = 2;
      });
    } else if (_step == 2) {
      // Confirm new PIN
      if (_pin == _newPin) {
        setState(() => _loading = true);
        try {
          await auth.changePin(_oldPin!, _newPin!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed successfully')));
            Navigator.pop(context);
          }
        } catch (e) {
          setState(() {
            _error = 'Failed to change PIN';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _pin = '';
          _newPin = null;
          _step = 1;
          _error = 'PINs do not match. Enter new PIN again.';
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String subtitle;
    switch (_step) {
      case 0:
        title = 'Enter Current PIN';
        subtitle = 'Verify your identity';
        break;
      case 1:
        title = 'Enter New PIN';
        subtitle = 'Create a new ${AppConstants.pinLength}-digit PIN';
        break;
      case 2:
      default:
        title = 'Confirm New PIN';
        subtitle = 'Re-enter your new PIN';
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Change PIN')),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Icon(
              _step == 0 ? Icons.lock_outline : Icons.lock_reset,
              size: 48,
              color: theme.colorScheme.primary
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
            Numpad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              enabled: !_loading,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

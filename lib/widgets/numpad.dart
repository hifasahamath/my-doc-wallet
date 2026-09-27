import 'package:flutter/material.dart';

class Numpad extends StatelessWidget {
  final void Function(int) onDigit;
  final VoidCallback onBackspace;
  final bool enabled;
  final double scaleFactor;

  const Numpad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hPadding = (32 * scaleFactor).clamp(16.0, 56.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Padding(
              padding: EdgeInsets.only(bottom: 16.0 * scaleFactor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var col = 0; col < 3; col++)
                    _buildNumpadButton(row, col, theme),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(int row, int col, ThemeData theme) {
    final btnSize = (64 * scaleFactor).clamp(54.0, 76.0);
    
    if (row < 3) {
      final digit = row * 3 + col + 1;
      return _digitButton(digit, theme, btnSize);
    }
    // Last row: empty, 0, backspace
    if (col == 0) return SizedBox(width: btnSize, height: btnSize);
    if (col == 1) return _digitButton(0, theme, btnSize);
    
    return SizedBox(
      width: btnSize,
      height: btnSize,
      child: IconButton(
        onPressed: enabled ? onBackspace : null,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
        ),
        icon: Icon(
          Icons.backspace_outlined, 
          color: theme.colorScheme.onSurface, 
          size: 24 * scaleFactor,
        ),
      ),
    );
  }

  Widget _digitButton(int digit, ThemeData theme, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: OutlinedButton(
        onPressed: enabled ? () => onDigit(digit) : null,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: theme.colorScheme.outlineVariant, 
            width: 1.0,
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Text(
          '$digit',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 26 * scaleFactor,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

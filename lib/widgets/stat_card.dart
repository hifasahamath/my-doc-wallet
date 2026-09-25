import 'package:flutter/material.dart';

/// A dashboard statistic card with consistent internal layout.
///
/// Every card shares the exact same structural template so that icon,
/// count, and label positions are guaranteed identical regardless of the
/// number of digits or the length of the label text.
///
/// Layout (top-to-bottom, left-aligned):
///   ┌──────────────────────┐
///   │  [icon]              │
///   │                      │
///   │  24                  │
///   │  Total               │
///   └──────────────────────┘
class StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge — fixed 40×40 square
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(icon, color: color, size: 22),
                      ),
                    ),
                  ),

                  // Flexible spacer pushes count+label to the bottom
                  const Spacer(),

                  // Count — monospace-style alignment with a fixed height
                  // so that 1, 24, 100, 999 all occupy the same vertical
                  // space and the label below never shifts.
                  SizedBox(
                    height: 36,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        count.toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          height: 1.0,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Label — single line, ellipsis for overflow
                  SizedBox(
                    height: 18,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

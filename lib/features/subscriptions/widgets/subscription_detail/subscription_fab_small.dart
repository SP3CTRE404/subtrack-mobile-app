import 'dart:ui';
import 'package:flutter/material.dart';

class SubscriptionFabSmall extends StatelessWidget {
  const SubscriptionFabSmall({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isVertical = true,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isVertical;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final glassBg = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.72);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.85);

    // Define the interactive button part with an expanded hit area (52x52)
    final buttonWithHitArea = Stack(
      alignment: Alignment.center,
      children: [
        // Invisible hit area extension for better touch precision
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(width: 52, height: 52),
        ),
        // Visual Small FAB (Liquid Glass)
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glassBg,
                    border: Border.all(
                      color: glassBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // Build the layout ensuring labels are outside the interactive stack
    if (isVertical) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          buttonWithHitArea,
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buttonWithHitArea,
          const SizedBox(height: 4),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
        ],
      );
    }
  }
}
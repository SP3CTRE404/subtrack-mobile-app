import 'dart:ui';
import 'package:flutter/material.dart';
import '../../settings/screens/settings_screen.dart';
import '../../subscriptions/screens/payment_history_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isScrolled;
  final String title;
  final Widget? trailingAction;

  const CustomAppBar({
    super.key,
    required this.isScrolled,
    required this.title,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isScrolled
                  ? (theme.brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.72))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isScrolled
                    ? (theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.7))
                    : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                );
              },
              child: Text(
                title,
                key: ValueKey<String>(title),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isScrolled
                      ? (theme.brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.72))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isScrolled
                        ? (theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.7))
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: 'History',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isScrolled
                      ? (theme.brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.72))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isScrolled
                        ? (theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.7))
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child:
                    trailingAction ??
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

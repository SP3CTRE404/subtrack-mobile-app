import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtrack/features/account/providers/account_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/providers/currency_provider.dart';
import '../models/subscription_model.dart';
import '../providers/history_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_role_provider.dart';
import '../models/user_role.dart';
import '../utils/subscription_ui_helper.dart';
import '../widgets/history/subscription_history_bubble.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final int? memberId;
  final String? memberName;

  const PaymentHistoryScreen({super.key, this.memberId, this.memberName});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(nativeCurrencyProvider);
    final theme = Theme.of(context);

    // If viewing a specific member's history (Admin View - Pushed Screen)
    if (widget.memberId != null) {
      final activeAsync = ref.watch(subscriptionProvider);
      final expiredAsync = ref.watch(
        memberExpiredSubscriptionsProvider(widget.memberId!),
      );

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('${widget.memberName}\'s History', style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: theme.brightness == Brightness.dark
                  ? const [
                      Color.fromARGB(255, 4, 42, 53),
                      Color(0xFF000000),
                    ]
                  : const [
                      Color.fromARGB(255, 137, 208, 230),
                      Color(0xFFF4F6F8),
                    ],
              stops: const [0.0, 0.8],
            ),
          ),
          child: activeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (activeList) {
              return expiredAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (expiredList) {
                  final memberActive = activeList
                      .where((s) => s.ownerId == widget.memberId)
                      .toList();
                  final allItems = [...memberActive, ...expiredList];

                  if (allItems.isEmpty) {
                    return const Center(child: Text('No subscriptions found.'));
                  }

                  // Sort by name
                  allItems.sort(
                    (a, b) => a.serviceName.toLowerCase().compareTo(
                      b.serviceName.toLowerCase(),
                    ),
                  );

                  final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 40),
                    itemCount: allItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sub = allItems[index];
                      return _SubscriptionHistoryListItem(
                        subscription: sub,
                        currencySymbol: currencySymbol,
                        onTap: () => _showHistoryBubble(sub, currencySymbol),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    }

    // Personal View (Pushed Screen)
    final activeAsync = ref.watch(subscriptionProvider);
    final expiredAsync = ref.watch(expiredSubscriptionsProvider);
    final userAsync = ref.watch(userProvider);
    final userRole = ref.watch(userRoleProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.3,
            colors: theme.brightness == Brightness.dark
                ? const [
                    Color.fromARGB(255, 4, 42, 53),
                    Color(0xFF000000),
                  ]
                : const [
                    Color.fromARGB(255, 137, 208, 230),
                    Color(0xFFF4F6F8),
                  ],
            stops: const [0.0, 0.8],
          ),
        ),
        child: _buildSubscriptionList(
          activeAsync: activeAsync,
          expiredAsync: expiredAsync,
          currencySymbol: currencySymbol,
          topPadding: MediaQuery.of(context).padding.top + kToolbarHeight,
          userRole: userRole,
          currentUserId: userAsync.value?.id,
        ),
      ),
    );
  }

  Widget _buildSubscriptionList({
    required AsyncValue<List<Subscription>> activeAsync,
    required AsyncValue<List<Subscription>> expiredAsync,
    required String currencySymbol,
    required double topPadding,
    required UserRole userRole,
    required int? currentUserId,
  }) {
    if (activeAsync.isLoading || expiredAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeItems = activeAsync.value ?? [];
    final expiredItems = expiredAsync.value ?? [];

    final viewableActive = userRole == UserRole.admin
        ? activeItems
        : activeItems.where((s) => s.ownerId == currentUserId).toList();

    final allItems = [...viewableActive, ...expiredItems];

    if (allItems.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: const Text('No subscriptions found.'),
        ),
      );
    }

    // Sort by name
    allItems.sort(
      (a, b) =>
          a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase()),
    );

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 40),
      itemCount: allItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sub = allItems[index];
        return _SubscriptionHistoryListItem(
          subscription: sub,
          currencySymbol: currencySymbol,
          onTap: () => _showHistoryBubble(sub, currencySymbol),
        );
      },
    );
  }

  void _showHistoryBubble(Subscription sub, String currencySymbol) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.2),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SubscriptionHistoryBubble(
            subscription: sub,
            currencySymbol: currencySymbol,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.fastLinearToSlowEaseIn,
            reverseCurve: Curves.fastOutSlowIn,
          );

          return AnimatedBuilder(
            animation: curved,
            builder: (context, child) {
              final t = curved.value;
              final blur = 12.0 * t;
              final tilt = -0.04 * t;

              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: FadeTransition(
                  opacity: curved,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..multiply(
                        Matrix4.diagonal3Values(
                          0.9 + (0.1 * t),
                          0.9 + (0.1 * t),
                          1.0,
                        ),
                      )
                      ..rotateX(tilt),
                    child: child!,
                  ),
                ),
              );
            },
            child: child,
          );
        },
      ),
    );
  }
}

class _SubscriptionHistoryListItem extends StatelessWidget {
  final Subscription subscription;
  final String currencySymbol;
  final VoidCallback onTap;

  const _SubscriptionHistoryListItem({
    required this.subscription,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = SubscriptionUIHelper.getIcon(subscription.serviceName);
    final isExpired = subscription.status == 'EXPIRED';

    return Hero(
      tag: 'sub_history_${subscription.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cobaltBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.cobaltBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.serviceName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isExpired)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'EXPIRED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

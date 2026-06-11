import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/subscription_model.dart';
import '../../providers/history_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../models/user_role.dart';
import '../../utils/subscription_ui_helper.dart';
import 'payment_history_card.dart';

class SubscriptionHistoryBubble extends ConsumerWidget {
  final Subscription subscription;
  final String currencySymbol;

  const SubscriptionHistoryBubble({
    super.key,
    required this.subscription,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider(subscription.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Hero(
            tag: 'sub_history_${subscription.id}',
            createRectTween: (begin, end) {
              return MaterialRectCenterArcTween(begin: begin, end: end);
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width - 48,
                constraints: BoxConstraints(
                  minHeight: screenHeight * 0.6,
                  maxHeight: screenHeight * 0.9,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.9)
                      : AppColors.lightSurface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.4),
                      blurRadius: 60,
                      offset: const Offset(0, 40),
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: SingleChildScrollView(
                      child: historyAsync.when(
                        data: (history) {
                          final sortedHistory = List.of(history)
                            ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader(context, ref),
                              Container(
                                constraints: BoxConstraints(
                                  minHeight: (screenHeight * 0.6) - 160,
                                ),
                                alignment: Alignment.center,
                                child: history.isEmpty 
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.history_rounded,
                                            size: 48,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No payment history yet.',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(), 
                                      itemCount: sortedHistory.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        return PaymentHistoryCard(
                                          payment: sortedHistory[index],
                                          currencySymbol: currencySymbol,
                                        );
                                      },
                                    ),
                              ),
                            ],
                          );
                        },
                        loading: () => Column(
                          children: [
                            _buildHeader(context, ref),
                            const SizedBox(height: 100),
                            const Center(child: CircularProgressIndicator()),
                          ],
                        ),
                        error: (err, stack) => Column(
                          children: [
                            _buildHeader(context, ref),
                            const SizedBox(height: 100),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 40),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error: $err',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: theme.colorScheme.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final icon = SubscriptionUIHelper.getIcon(subscription.serviceName);
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == UserRole.admin;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cobaltBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isAdmin && subscription.ownerName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 12,
                            color: AppColors.cobaltBlue.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subscription.ownerName!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.cobaltBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

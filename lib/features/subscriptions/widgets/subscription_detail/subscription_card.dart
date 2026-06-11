import 'package:flutter/material.dart';
import 'package:subtrack/core/utils/currency_formatter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/subscription_model.dart';
import '../../utils/subscription_ui_helper.dart';
import '../../../../shared/widgets/icon_detail_item.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final String currencySymbol;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool showMadeBy;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.currencySymbol,
    required this.isExpanded,
    required this.onTap,
    this.showMadeBy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final IconData icon = SubscriptionUIHelper.getIcon(subscription.serviceName);
    final Color statusColor = SubscriptionUIHelper.getStatusColor(
      isOverdue: subscription.isOverdue,
      isUpcoming: subscription.isUpcoming,
      daysUntilDue: subscription.daysUntilDue,
      isAutoPay: subscription.isAutoPay,
      isDark: theme.brightness == Brightness.dark,
    );
    final String dueStatus = SubscriptionUIHelper.getDueStatus(
      isOverdue: subscription.isOverdue,
      isUpcoming: subscription.isUpcoming,
      daysUntilDue: subscription.daysUntilDue,
      isAutoPay: subscription.isAutoPay,
    );

    final String paymentType = subscription.isAutoPay ? 'Auto-pay' : 'Manual';
    final String billingCycle = SubscriptionUIHelper.formatBillingCycle(
      subscription.billingCycle,
      value: subscription.customIntervalDays,
      unit: subscription.customIntervalUnit,
    );

    final String subDateFormatted = SubscriptionUIHelper.formatDate(subscription.purchaseDate);

    return Card(
      color: theme.cardTheme.color ?? colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: isExpanded ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isExpanded
              ? colorScheme.primary.withValues(alpha: 0.5)
              : (theme.brightness == Brightness.light 
                  ? Colors.black.withValues(alpha: 0.08) 
                  : Colors.transparent),
          width: isExpanded ? 1.5 : 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      icon,
                      color: AppColors.cobaltBlue,
                    ),
                  ),
                  title: Text(
                    subscription.serviceName,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      dueStatus,
                      style: textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(subscription.amount, subscription.currency ?? currencySymbol),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: colorScheme.onSurface.withValues(alpha: 0.54),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                      top: 4.0,
                    ),
                    child: Column(
                      children: [
                        Divider(
                          color: colorScheme.onSurface.withValues(alpha: 0.12),
                          height: 24,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: showMadeBy
                              ? Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: IconDetailItem(
                                            label: 'Billing Cycle',
                                            value: billingCycle,
                                            icon: Icons.calendar_month_outlined,
                                          ),
                                        ),
                                        Expanded(
                                          child: IconDetailItem(
                                            label: 'Method',
                                            value: paymentType,
                                            icon: Icons.payment_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: IconDetailItem(
                                            label: 'Puchased On',
                                            value: subDateFormatted,
                                            icon:
                                                Icons.event_available_outlined,
                                          ),
                                        ),
                                        Expanded(
                                          child: IconDetailItem(
                                            label: 'Owner:',
                                            value: subscription.ownerName ?? 'Unknown',
                                            icon: Icons.person_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: IconDetailItem(
                                        label: 'Billing Cycle',
                                        value: billingCycle,
                                        icon: Icons.calendar_month_outlined,
                                      ),
                                    ),
                                    Expanded(
                                      child: IconDetailItem(
                                        label: 'Method',
                                        value: paymentType,
                                        icon: Icons.payment_outlined,
                                      ),
                                    ),
                                    Expanded(
                                      child: IconDetailItem(
                                        label: 'Purchased On',
                                        value: subDateFormatted,
                                        icon: Icons.event_available_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

  }
}


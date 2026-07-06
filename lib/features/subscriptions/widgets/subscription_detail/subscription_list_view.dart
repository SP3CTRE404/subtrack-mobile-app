import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/subscription_model.dart';
import '../../screens/add_subscription_screen.dart';
import 'subscription_card.dart';

class SubscriptionListView extends StatelessWidget {
  final List<Subscription> subscriptions;
  final String currencySymbol;
  final Set<String> expandedCards;
  final Function(String) onToggleCard;
  final String tabPrefix;
  final bool showMadeBy;

  const SubscriptionListView({
    super.key,
    required this.subscriptions,
    required this.currencySymbol,
    required this.expandedCards,
    required this.onToggleCard,
    required this.tabPrefix,
    required this.showMadeBy,
  });

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cobaltBlue15,
                  border: Border.all(
                    color: AppColors.cobaltBlue30,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cobaltBlue20,
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.subscriptions_outlined,
                  size: 42,
                  color: AppColors.cobaltBlue,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'No Subscriptions Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first subscription to start tracking your recurring expenses automatically.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.onSurfaceDark60 : AppColors.onSurfaceLight60,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddSubscriptionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cobaltBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.cobaltBlue40,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Add Subscription',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(
        top: 100.0,
        bottom: 130.0,
        left: 16.0,
        right: 16.0,
      ),
      itemCount: subscriptions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        final cardKey = '${tabPrefix}_$index';
        final isExpanded = expandedCards.contains(cardKey);

        return SubscriptionCard(
          subscription: sub,
          currencySymbol: currencySymbol,
          isExpanded: isExpanded,
          onTap: () => onToggleCard(cardKey),
          showMadeBy: showMadeBy,
        );
      },
    );
  }
}

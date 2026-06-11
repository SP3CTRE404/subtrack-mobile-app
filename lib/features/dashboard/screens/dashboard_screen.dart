import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtrack/features/subscriptions/models/subscription_model.dart';
import 'package:subtrack/features/subscriptions/screens/add_subscription_screen.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../shared/widgets/skeleton_card.dart';
import '../../account/providers/account_provider.dart';
import '../../settings/providers/currency_provider.dart';
import '../../subscriptions/models/user_role.dart';
import '../../subscriptions/providers/user_role_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/action_card_list.dart';
import '../widgets/financial_hero_card.dart';
import '../../tutorial/widgets/tutorial_anchor.dart';
import '../../tutorial/widgets/tutorial_bubble.dart';

enum DashboardViewMode { personal, household }


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardViewMode _viewMode = DashboardViewMode.personal;

  final Set<int> _paidItems = {}; 
  
  Future<void> _handleRefresh() async {
    // We use the notifier's refresh method to preserve UI state 
    // instead of ref.invalidate() which destroys the state and causes UI jumps.
    await ref.read(subscriptionProvider.notifier).refresh();
    // ignore: unused_result
    ref.refresh(userProvider);
  }


  @override
  Widget build(BuildContext context) {
    final displayCurrency = ref.watch(displayCurrencyProvider);
    final nativeCurrency = ref.watch(nativeCurrencyProvider);
    final userAsync = ref.watch(userProvider);
    final subscriptionsAsync = ref.watch(subscriptionProvider);
    final monthlyTotalAsync = ref.watch(monthlyTotalProvider);
    final userRole = ref.watch(userRoleProvider);
    
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight - 40;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: 100, // Move it below the transparent app bar area
      edgeOffset: topPadding,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TutorialAnchor(
                      tutorialId: 'dashboard_hello',
                      title: 'Welcome to Premio!',
                      description: "This is your dashboard. Let's take a quick tour of your subscription management center.",
                      arrowDirection: ArrowDirection.up,
                      alignment: BubbleAlignment.right,
                      child: Text(
                        'Hello, ${user?.fullName.split(' ').first ?? 'User'}!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userRole == UserRole.single 
                          ? 'Keep your personal subscriptions in check.' 
                          : 'Here is your subscription overview.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 60),
              error: (err, stack) => const SizedBox.shrink(),
            ),
  
            subscriptionsAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => const DashboardSkeleton(),
              error: (err, stack) => Text('Failed to load subscriptions: $err'),
              data: (allSubs) {
                final isAdmin = userRole == UserRole.admin;
                final currentUserId = userAsync.value?.id;
  
                // What this user is ALLOWED to see on their dashboard
                final viewableSubs = isAdmin
                    ? allSubs // Admins see everything for the overview
                    : allSubs.where((s) => s.ownerId == currentUserId).toList(); // Members only see their own
  
                // Action Needed list filtering (Specific focus for Admins)
                final filteredSubs = (isAdmin && _viewMode == DashboardViewMode.personal)
                    ? viewableSubs.where((s) => s.ownerId == currentUserId).toList()
                    : (isAdmin && _viewMode == DashboardViewMode.household)
                        ? viewableSubs.where((s) => s.ownerId != currentUserId).toList()
                        : viewableSubs;
  
                final overdue = viewableSubs.where((s) => s.isOverdue).length;
  
                final dueSoon = viewableSubs.where((s) => s.isUpcoming).length;
  
                final upToDate = viewableSubs.length - overdue - dueSoon;
  
  
                final actionNeeded = filteredSubs.where((s) {
                  if (s.isAutoPay) return false;
                  return s.isOverdue || s.isUpcoming;
                }).toList();
  
                if (viewableSubs.isEmpty) {
                    return const _DashboardEmptyState();
                }
  
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    monthlyTotalAsync.when(
                      skipLoadingOnReload: true,
                      skipLoadingOnRefresh: true,
                      data: (householdMonthly) {
                        double displayMonthly = 0.0;
                        for (final sub in viewableSubs) {
                          if (sub.status == 'EXPIRED') continue;

                          double monthlyEquivalent = sub.amount;
                          switch (sub.billingCycle) {
                            case BillingCycle.yearly:
                              monthlyEquivalent = sub.amount / 12;
                              break;
                            case BillingCycle.quarterly:
                              monthlyEquivalent = sub.amount / 3;
                              break;
                            case BillingCycle.oneTime:
                              continue;
                            case BillingCycle.custom:
                              if (sub.customIntervalUnit == 'MONTHS') {
                                monthlyEquivalent = sub.amount / (sub.customIntervalDays ?? 1);
                              } else if (sub.customIntervalUnit == 'DAYS') {
                                monthlyEquivalent = sub.amount * (30 / (sub.customIntervalDays ?? 30));
                              } else if (sub.customIntervalUnit == 'WEEKS') {
                                monthlyEquivalent = sub.amount * (4 / (sub.customIntervalDays ?? 1));
                              }
                              break;
                            case BillingCycle.monthly:
                            monthlyEquivalent = sub.amount;
                              break;
                          }

                          final subCurrency = sub.currency ?? nativeCurrency;
                          final convertedAmount = CurrencyConverter.convert(
                            amount: monthlyEquivalent,
                            fromCurrency: subCurrency,
                            toCurrency: displayCurrency,
                          );

                          displayMonthly += convertedAmount;
                        }
                        
                        final personalCount = viewableSubs.where((s) => s.ownerId == currentUserId).length;
                        final householdCount = viewableSubs.where((s) => s.ownerId != currentUserId).length;
                            
                        return TutorialAnchor(
                          tutorialId: 'dashboard_hero',
                          title: 'Financial Overview',
                          description: 'Track your total monthly subscription costs, along with status counts of active, upcoming, and overdue payments at a glance.',
                          arrowDirection: ArrowDirection.up,
                          alignment: BubbleAlignment.center,
                          child: FinancialHeroCard(
                            monthly: displayMonthly,
                            upToDate: upToDate,
                            dueSoon: dueSoon,
                            overdue: overdue,
                            currencySymbol: displayCurrency,
                            isAdmin: isAdmin,
                            personalCount: personalCount,
                            householdCount: householdCount,
                          ),
                        );
                      },
                      loading: () => const SkeletonHeroCard(),
                      error: (err, st) => FinancialHeroCard(
                        monthly: 0,
                        upToDate: 0,
                        dueSoon: 0,
                        overdue: 0,
                        currencySymbol: displayCurrency,
                        isAdmin: isAdmin,
                      ),
                    ),
  
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TutorialAnchor(
                            tutorialId: 'dashboard_action_needed',
                            title: 'Payments Action List',
                            description: 'Any manual-pay subscriptions that are upcoming or overdue will show up here. Mark them as paid to keep them up to date.',
                            arrowDirection: ArrowDirection.up,
                            alignment: BubbleAlignment.right,
                            child: _sectionTitle(context, 'Action Needed'),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 12),
                          _buildViewToggle(context),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    ActionCardList(
                      subscriptions: actionNeeded, 
                      paidItems: _paidItems.map((e) => e.toString()).toSet(), 
                      currencySymbol: nativeCurrency,
                      showOwner: _viewMode == DashboardViewMode.household,
                      onTogglePaid: (idString) async {
                        final id = int.parse(idString);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref.read(subscriptionProvider.notifier).pay(id);
                          
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Payment confirmed!')),
                            );
                            setState(() {
                              _paidItems.remove(id);
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to confirm payment: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context) {
    final theme = Theme.of(context);
    final isPersonal = _viewMode == DashboardViewMode.personal;
    
    return Container(
      width: 160,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                // Inner highlight (top)
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Liquid Indicator
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  alignment: isPersonal ? Alignment.centerLeft : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                            // Subtle inner highlight on indicator
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                              spreadRadius: -0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Labels
                Row(
                  children: [
                    _buildToggleButton(
                      context: context,
                      label: 'Personal',
                      isSelected: isPersonal,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _viewMode = DashboardViewMode.personal);
                      },
                    ),
                    _buildToggleButton(
                      context: context,
                      label: 'Household',
                      isSelected: !isPersonal,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _viewMode = DashboardViewMode.household);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: -0.2,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }


  Widget _sectionTitle(BuildContext context, String title) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardTheme.color!,
            theme.cardTheme.color!.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Ready to Track?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Add your first subscription to see your personal financial overview and insights.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
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
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 28),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add a Subscription',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


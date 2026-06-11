import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/providers/account_provider.dart';
import '../../settings/providers/currency_provider.dart';
import '../models/user_role.dart';
import '../providers/user_role_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/subscription_detail/subscription_fab_small.dart';
import '../widgets/subscription_detail/subscription_list_view.dart';
import 'add_subscription_screen.dart';
import '../../../core/theme/app_colors.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  const SubscriptionDetailScreen({super.key});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Track which cards are expanded by a combination of key prefix ("mine_" or "all_") and index
  final Set<String> _expandedCards = {};

  void _toggleCard(String cardKey) {
    setState(() {
      if (_expandedCards.contains(cardKey)) {
        _expandedCards.remove(cardKey);
      } else {
        _expandedCards.add(cardKey);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(nativeCurrencyProvider);
    final userRole = ref.watch(userRoleProvider);
    final userAsync = ref.watch(userProvider);
    final subscriptionsAsync = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          subscriptionsAsync.when(
            data: (allSubs) {
              final userFullName = userAsync.value?.fullName ?? '';
              var mySubs = allSubs.where((s) => s.ownerName == userFullName).toList();
              var householdSubs = allSubs.where((s) => s.ownerName != userFullName).toList();

              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                mySubs = mySubs.where((s) => s.serviceName.toLowerCase().contains(query)).toList();
                householdSubs = householdSubs.where((s) => s.serviceName.toLowerCase().contains(query)).toList();
              }

              if (userRole != UserRole.admin) {
                return SubscriptionListView(
                  subscriptions: mySubs,
                  currencySymbol: currencySymbol,
                  expandedCards: _expandedCards,
                  onToggleCard: _toggleCard,
                  tabPrefix: 'single',
                  showMadeBy: false,
                );
              }

              return DefaultTabController(
                length: 2,
                child: Stack(
                  children: [
                    TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        SubscriptionListView(
                          subscriptions: mySubs,
                          currencySymbol: currencySymbol,
                          expandedCards: _expandedCards,
                          onToggleCard: _toggleCard,
                          tabPrefix: 'mine',
                          showMadeBy: false,
                        ),
                        SubscriptionListView(
                          subscriptions: householdSubs,
                          currencySymbol: currencySymbol,
                          expandedCards: _expandedCards,
                          onToggleCard: _toggleCard,
                          tabPrefix: 'household',
                          showMadeBy: true,
                        ),
                      ],
                    ),
                    _buildTabPill(context),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),

          // 1. Add Button (top of vertical stack)
          // right:15 so the visual 42px circle's edge sits at right:20
          // (SubscriptionFabSmall has a 52px hit area — 5px padding each side)
          Positioned(
            right: 15,
            bottom: 143,
            child: IgnorePointer(
              ignoring: _isSearching,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isSearching ? 0.0 : 1.0,
                child: SubscriptionFabSmall(
                  icon: Icons.add,
                  label: 'Add Subscription',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
                    );
                  },
                  showLabel: false,
                ),
              ),
            ),
          ),

          // 2. Search Button / Bar (bottom of vertical stack, expands to full width)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            left: _isSearching ? 20 : null,
            right: 20,
            width: _isSearching ? null : 42,
            bottom: _isSearching
                ? 16 + MediaQuery.of(context).viewInsets.bottom
                : 96,
            height: 42,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      color: theme.brightness == Brightness.dark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.72),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.85),
                        width: 1.2,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _isSearching
                          ? SingleChildScrollView(
                              key: const ValueKey('search_active'),
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 40,
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12, right: 8),
                                      child: Icon(
                                        Icons.search_rounded,
                                        size: 20,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        autofocus: true,
                                        onChanged: (val) {
                                          setState(() {
                                            _searchQuery = val;
                                          });
                                        },
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Search...',
                                          hintStyle: TextStyle(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSearching = false;
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GestureDetector(
                              key: const ValueKey('search_collapsed'),
                              onTap: () {
                                setState(() {
                                  _isSearching = true;
                                });
                              },
                              child: Center(
                                child: Icon(
                                  Icons.search_rounded,
                                  color: theme.colorScheme.onSurface,
                                  size: 20,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 86,
      child: IgnorePointer(
        ignoring: _isSearching,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: _isSearching ? 0.0 : 1.0,
          child: Center(
            child: Container(
              width: 130,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? theme.colorScheme.surface.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.1),
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
                                  Colors.white.withValues(alpha: isDark ? 0.2 : 0.4),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        TabBar(
                          onTap: (_) => HapticFeedback.lightImpact(),
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.cobaltBlue,
                                Color(0xFF4A90E2), // Lighter shade for liquid effect
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cobaltBlue.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              // Subtle inner highlight on indicator
                              const BoxShadow(
                                color: Colors.white24,
                                blurRadius: 1,
                                offset: Offset(0, 1),
                                spreadRadius: -0.5,
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                          tabs: const [
                            Tab(text: "Mine"),
                            Tab(text: "All"),
                          ],
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
    );
  }
}

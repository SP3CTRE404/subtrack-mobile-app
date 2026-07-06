import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:subtrack/features/settings/providers/currency_provider.dart';
import '../../auth/widgets/auth_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../../account/providers/account_provider.dart';
import 'add_subscription_screen.dart';
import '../models/subscription_model.dart';
import '../widgets/edit_subscription/edit_subscription_card.dart';
import '../widgets/edit_subscription/subscription_search_bar.dart';
import '../widgets/edit_subscription/end_subscription_dialog.dart';
import '../../../../shared/widgets/destructive_action_dialog.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../shared/widgets/custom_toast.dart';
import '../../../../core/theme/app_colors.dart';

class EditSubscriptionsScreen extends ConsumerStatefulWidget {

  final String? memberName;
  const EditSubscriptionsScreen({super.key, this.memberName});

  @override
  ConsumerState<EditSubscriptionsScreen> createState() => _EditSubscriptionsScreenState();
}

class _EditSubscriptionsScreenState extends ConsumerState<EditSubscriptionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";
  Timer? _debounce;
  bool _isScrolled = false;
  
  Future<void> _handleRefresh() async {
    ref.invalidate(subscriptionProvider);
    ref.invalidate(userProvider);
    await ref.read(subscriptionProvider.future);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isScrolled = _scrollController.offset > 10;
        if (isScrolled != _isScrolled) {
          setState(() {
            _isScrolled = isScrolled;
          });
        }
      }
    });
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = val);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmEndSubscription(Subscription sub) {
    showDialog(
      context: context,
      builder: (context) => EndSubscriptionDialog(
        sub: sub,
        onConfirm: () {}, // Handled internally by dialog now
      ),
    );
  }


  void _confirmDeleteSubscription(Subscription sub) {
    showDialog(
      context: context,
      builder: (context) => DestructiveActionDialog(
        title: 'Delete Subscription?',
        content: 'Are you sure you want to permanently delete your "${sub.serviceName}" subscription? All the payment history will be lost. This action cannot be undone.',
        actionText: 'Delete Forever',
        onConfirm: () async {
          final authenticated = await ref.read(authServiceProvider).verifyUser(context);
          if (!authenticated) return;
          
          if (!context.mounted) return;
          try {
            await ref.read(subscriptionProvider.notifier).delete(sub.id);
            if (context.mounted) {
              Navigator.pop(context);
              CustomToast.show(
                context: context, 
                message: '${sub.serviceName} deleted permanently', 
                isError: false,
              );
            }
          } catch (e) {
            if (context.mounted) {
              CustomToast.show(
                context: context, 
                message: 'Failed to delete: $e', 
                isError: true,
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProvider);
    final subscriptionsAsync = ref.watch(subscriptionProvider);
    final currencySymbol = ref.watch(nativeCurrencyProvider);
    
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          widget.memberName != null ? 'Edit ${widget.memberName}\'s Subs' : 'Manage Subscriptions', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                offset: const Offset(0, 1),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: AnimatedOpacity(
          opacity: _isScrolled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.3),
                      theme.colorScheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const AuthBackground(),
          
          subscriptionsAsync.when(
            data: (allSubs) {
              final userFullName = userAsync.value?.fullName ?? '';
              final targetUser = widget.memberName ?? userFullName;
              
              final filteredSubs = allSubs.where((sub) {
                final matchesSearch = sub.serviceName.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesUser = sub.ownerName == targetUser;
                return matchesSearch && matchesUser;
              }).toList();

              if (filteredSubs.isEmpty) {
                if (_searchQuery.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'No matching subscriptions found.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cobaltBlue15,
                            border: Border.all(
                              color: AppColors.cobaltBlue30,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.subscriptions_outlined,
                            size: 38,
                            color: AppColors.cobaltBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Subscriptions to Manage',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Add a subscription first to manage, edit, or end your active billing plans.',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Add Subscription',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _handleRefresh,
                displacement: 100,
                edgeOffset: 10,
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 120, 16, 140 + bottomInset),
                  itemCount: filteredSubs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sub = filteredSubs[index];
                    return EditSubscriptionCard(
                      sub: sub,
                      currencySymbol: currencySymbol,
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddSubscriptionScreen(initialData: sub),
                        ),
                      ),
                      onEnd: () => _confirmEndSubscription(sub),
                      onDelete: () => _confirmDeleteSubscription(sub),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),

          SubscriptionSearchBar(
            controller: _searchController,
            query: _searchQuery,
            onChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }
}


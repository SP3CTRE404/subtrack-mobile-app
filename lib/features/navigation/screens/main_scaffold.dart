import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtrack/features/subscriptions/models/user_role.dart';
import 'package:subtrack/features/subscriptions/providers/user_role_provider.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../subscriptions/screens/subscription_detail_screen.dart';
import '../../subscriptions/screens/edit_subscriptions_screen.dart';
import '../../account/screens/account_screen.dart';
import '../../household/screens/household_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../tutorial/providers/tutorial_provider.dart';

import '../../account/providers/account_provider.dart';
import '../../household/screens/join_household_screen.dart';
import '../../../core/notifications/providers/notification_check_provider.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _isScrolled = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(navigationIndexProvider);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.axis == Axis.vertical) {
      final metrics = notification.metrics;
      final scrolled = metrics.pixels > 10;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationCheckProvider);
    final currentIndex = ref.watch(navigationIndexProvider);
    final userRole = ref.watch(userRoleProvider);
    final isSingle = userRole == UserRole.single;

    // Fix #2: Only select the fields we actually need for the minor check
    final isMinorWithoutHousehold = ref.watch(
      userProvider.select((asyncUser) {
        final user = asyncUser.value;
        if (user == null) return false;
        return user.dateOfBirth != null &&
            user.age >= 0 &&
            user.age < 18 &&
            user.householdId == null;
      }),
    );
    final isLoading = ref.watch(userProvider.select((u) => u.isLoading));
    final hasError = ref.watch(userProvider.select((u) => u.hasError));
    final errorMessage = ref.watch(
      userProvider.select((u) => u.error?.toString() ?? ''),
    );

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (hasError) {
      return Scaffold(body: Center(child: Text('Error: $errorMessage')));
    }

    if (isMinorWithoutHousehold) {
      return const Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(title: 'Join a Household', isScrolled: false),
        body: JoinHouseholdScreen(),
      );
    }

    final List<Widget> screens = [
      const DashboardScreen(),
      const SubscriptionDetailScreen(),
      const HouseholdScreen(),
      const AccountScreen(),
    ];

    final List<String> titles = [
      'Premio',
      'Subscriptions',
      isSingle ? 'Collaborate' : 'Household',
      'Account',
    ];

    ref.listen(navigationIndexProvider, (previous, next) {
      setState(() {
        _isScrolled = false;
      });
      if (_pageController.hasClients) {
        final currentPage = _pageController.page?.round() ?? _pageController.initialPage;
        if (currentPage != next) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });

    ref.listen(tutorialProvider, (previous, next) {
      if (previous == null || previous.value == null) return;

      final prevStep = previous.value?.activeStep;
      final activeStep = next.value?.activeStep;
      if (prevStep == activeStep) return;

      if (activeStep == 'dashboard_hello') {
        ref.read(navigationIndexProvider.notifier).setIndex(0);
      } else if (activeStep == 'bottom_nav_household') {
        ref.read(navigationIndexProvider.notifier).setIndex(2);
      } else if (activeStep == 'bottom_nav_subscriptions') {
        ref.read(navigationIndexProvider.notifier).setIndex(1);
      } else if (activeStep == 'bottom_nav_account') {
        ref.read(navigationIndexProvider.notifier).setIndex(3);
      }
    });

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        isScrolled: _isScrolled,
        title: titles[currentIndex],
        showHistoryButton: currentIndex == 1,
        trailingAction: currentIndex == 1
            ? IconButton(
                icon: const Icon(Icons.edit_note_rounded),
                tooltip: 'Manage Subscriptions',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditSubscriptionsScreen(),
                    ),
                  );
                },
              )
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.3,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
                    Color.fromARGB(255, 4, 42, 53), // Very subtle premium green glow
                    Color(0xFF000000), // Pure black background
                  ]
                : const [
                    Color.fromARGB(255, 137, 208, 230), // Subtle soft green/mint glow for light mode
                    Color(0xFFF4F6F8), // Crisp light surface background
                  ],
            stops: const [0.0, 0.8],
          ),
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              ref.read(navigationIndexProvider.notifier).setIndex(index);
            },
            children: screens.asMap().entries.map((entry) {
              return SizedBox.expand(
                key: ValueKey<int>(entry.key),
                child: entry.value,
              );
            }).toList(),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : const BottomNavBar(isPill: true),
    );
  }
}

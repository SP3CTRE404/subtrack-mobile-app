import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtrack/features/account/providers/account_provider.dart';
import '../models/history_model.dart';
import '../models/subscription_model.dart';
import '../services/history_repository.dart';
import '../services/subscription_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../household/providers/household_provider.dart';
import 'subscription_provider.dart';

/// Fetches payment history for a specific subscription ID.
final historyProvider = FutureProvider.autoDispose.family<List<SubscriptionHistory>, int>(
  (ref, subscriptionId) async {
    if (subscriptionId <= 0) {
      return [
        SubscriptionHistory(
          id: -1,
          subscriptionId: subscriptionId,
          serviceName: 'Mock Payment',
          amount: 9.99,
          paymentDate: DateTime.now().subtract(const Duration(days: 30)),
          status: 'Paid',
        ),
      ];
    }

    final repo = ref.read(historyRepositoryProvider);
    try {
      return await repo.getHistory(subscriptionId).timeout(const Duration(seconds: 10));
    } catch (e) {
      try {
        // Look up the subscription to find the correct ownerId
        int? ownerId;
        final activeSubs = ref.read(subscriptionProvider).value;
        if (activeSubs != null) {
          final match = activeSubs.where((s) => s.id == subscriptionId);
          if (match.isNotEmpty) {
            ownerId = match.first.ownerId;
          }
        }
        
        // If not found in active subscriptions, look in the current user's expired list
        if (ownerId == null) {
          final expiredSubs = ref.read(expiredSubscriptionsProvider).value;
          if (expiredSubs != null) {
            final match = expiredSubs.where((s) => s.id == subscriptionId);
            if (match.isNotEmpty) {
              ownerId = match.first.ownerId;
            }
          }
        }

        // If still not found, search in all household members' expired subscription lists
        if (ownerId == null) {
          final household = ref.read(householdProvider).value;
          if (household != null) {
            final members = household['members'] as List<dynamic>?;
            if (members != null) {
              for (final member in members) {
                final memberId = member['id'] as int?;
                if (memberId != null) {
                  final expiredSubs = ref.read(memberExpiredSubscriptionsProvider(memberId)).value;
                  if (expiredSubs != null) {
                    final match = expiredSubs.where((s) => s.id == subscriptionId);
                    if (match.isNotEmpty) {
                      ownerId = memberId;
                      break;
                    }
                  }
                }
              }
            }
          }
        }

        // Default fallback to currently logged-in user
        if (ownerId == null) {
          final currentUser = ref.read(userProvider).value;
          ownerId = currentUser?.id;
        }

        final allHistory = await repo.getUserHistory(userId: ownerId, page: 0, size: 100);
        return allHistory.items.where((item) => item.subscriptionId == subscriptionId).toList();
      } catch (innerError) {
        rethrow;
      }
    }
  },
);

/// Holds a page of history items plus pagination metadata.
class PaginatedHistoryState {
  final List<SubscriptionHistory> items;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginatedHistoryState({
    this.items = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginatedHistoryState copyWith({
    List<SubscriptionHistory>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedHistoryState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Simple non-paginated provider for backwards compatibility.
final userHistoryProvider = FutureProvider.autoDispose<List<SubscriptionHistory>>((ref) async {
  ref.watch(authProvider);
  final repo = ref.read(historyRepositoryProvider);
  final result = await repo.getUserHistory(page: 0, size: 20);
  return result.items;
});

/// Notifier for paginated history with loadMore support.
class PaginatedHistoryNotifier extends Notifier<PaginatedHistoryState> {
  int _currentPage = 0;
  static const _pageSize = 20;

  @override
  PaginatedHistoryState build() {
    _fetchInitial();
    return const PaginatedHistoryState();
  }

  Future<void> _fetchInitial() async {
    _currentPage = 0;
    try {
      final repo = ref.read(historyRepositoryProvider);
      final result = await repo.getUserHistory(page: 0, size: _pageSize);
      _currentPage = 1;
      state = PaginatedHistoryState(
        items: result.items,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = const PaginatedHistoryState(items: [], hasMore: false);
    }
  }

  bool get hasMore => state.hasMore;
  bool get isLoadingMore => state.isLoadingMore;

  /// Loads the next page and appends items to current list.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final repo = ref.read(historyRepositoryProvider);
      final result = await repo.getUserHistory(page: _currentPage, size: _pageSize);
      _currentPage++;
      state = PaginatedHistoryState(
        items: [...state.items, ...result.items],
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await _fetchInitial();
  }
}

final paginatedHistoryProvider = NotifierProvider<PaginatedHistoryNotifier, PaginatedHistoryState>(
  PaginatedHistoryNotifier.new,
);

/// Fetches all expired subscriptions for the logged-in user.
final expiredSubscriptionsProvider = FutureProvider.autoDispose<List<Subscription>>((ref) async {
  ref.watch(authProvider);
  final repo = ref.read(subscriptionRepositoryProvider);
  return repo.getExpiredSubscriptions();
});

/// Fetches payment history for a specific member (Admin only).
final memberHistoryProvider = FutureProvider.autoDispose.family<List<SubscriptionHistory>, int>((ref, userId) async {
  final repo = ref.read(historyRepositoryProvider);
  final result = await repo.getUserHistory(userId: userId, page: 0, size: 100);
  return result.items;
});

/// Fetches expired subscriptions for a specific member (Admin only).
final memberExpiredSubscriptionsProvider = FutureProvider.autoDispose.family<List<Subscription>, int>((ref, userId) async {
  final repo = ref.read(subscriptionRepositoryProvider);
  return repo.getExpiredSubscriptions(userId: userId);
});

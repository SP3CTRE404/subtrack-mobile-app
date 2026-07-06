/// Centralized API route constants.
class ApiEndpoints {
  // ── Auth (public, no token needed) ──
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';

  static String monthlyTotal(int userId) => '/api/subscriptions/user/$userId/monthly-total';
  static String dueSubscriptions(int userId) => '/api/subscriptions/user/$userId/due';
  static String allSubscriptions(int userId) => '/api/subscriptions/user/$userId';
  static String householdSubscriptions(int householdId) => '/api/subscriptions/household/$householdId';
  static const String addSubscription = '/api/subscriptions/add';
  static String updateSubscription(int id) => '/api/subscriptions/$id';
  static String deleteSubscription(int id) => '/api/subscriptions/$id';
  static String expireSubscription(int id) => '/api/subscriptions/$id/expire';
  static String paySubscription(int id) => '/api/subscriptions/$id/pay';
  static String toggleAutoPay(int id) => '/api/subscriptions/$id/toggle-autopay';
  static String expiredSubscriptions(int userId) => '/api/subscriptions/user/$userId/expired';
  static String userHistory(int userId) => '/api/subscriptions/user/$userId/history';
  static String subscriptionHistory(int subscriptionId) => '/api/subscriptions/$subscriptionId/history';

  // ── Notifications ──
  static const String pendingNotifications = '/api/notifications/pending';
  static String markNotificationRead(int id) => '/api/notifications/$id/read';
}

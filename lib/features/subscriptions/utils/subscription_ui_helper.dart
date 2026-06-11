import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';


/// Helper to get consistent icons and colors for subscriptions based on their names.
class SubscriptionUIHelper {
  static String formatBillingCycle(BillingCycle cycle, {int? value, String? unit}) {
    if (cycle == BillingCycle.oneTime) return 'One-time';
    if (cycle != BillingCycle.custom) {
      return cycle.name[0].toUpperCase() + cycle.name.substring(1);
    }
    if (value == null) return 'Custom';
    final unitStr = unit?.toLowerCase() ?? 'days';
    final displayUnit = value == 1 ? unitStr.substring(0, unitStr.length - 1) : unitStr;
    return 'Every $value ${displayUnit[0].toUpperCase() + displayUnit.substring(1)}';
  }

  static IconData getIcon(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('youtube') ||
        lower.contains('netflix') ||
        lower.contains('prime') ||
        lower.contains('disney')) {
      return Icons.play_circle_fill_rounded;
    }
    if (lower.contains('amazon') ||
        lower.contains('ebay') ||
        lower.contains('cart')) {
      return Icons.shopping_cart_rounded;
    }
    if (lower.contains('spotify') ||
        lower.contains('apple music') ||
        lower.contains('music')) {
      return Icons.music_note_rounded;
    }
    if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }
    if (lower.contains('cloud') ||
        lower.contains('drive') ||
        lower.contains('icloud')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('microsoft') || lower.contains('365') || lower.contains('office')) {
      return Icons.description_rounded;
    }
    if (lower.contains('playstation') || lower.contains('xbox') || lower.contains('games')) {
      return Icons.games_rounded;
    }
    if (lower.contains('zomato') || lower.contains('swiggy') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    return Icons.subscriptions_rounded;
  }

  static Color getStatusColor({
    required bool isOverdue,
    required bool isUpcoming,
    required int daysUntilDue,
    bool isAutoPay = false,
    bool isDark = false,
  }) {
    if (isAutoPay) {
      if (daysUntilDue == 0 || daysUntilDue == 1) return Colors.amber;
      return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    }
    if (isOverdue || daysUntilDue < 0) {
      return Colors.redAccent;
    }
    if (daysUntilDue == 0) return Colors.amber;
    if (isUpcoming) return Colors.amber;
    return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  }

  static String getDueStatus({
    required bool isOverdue,
    required bool isUpcoming,
    required int daysUntilDue,
    bool isAutoPay = false,
  }) {
    if (isAutoPay) {
      if (daysUntilDue < 0) {
        return 'Auto-renewed';
      }
      if (daysUntilDue == 0) {
        return 'Renewing today';
      }
      if (daysUntilDue == 1) {
        return 'Renewing tomorrow';
      }
      return 'Auto-pays in $daysUntilDue ${daysUntilDue == 1 ? 'day' : 'days'}';
    }
    if (isOverdue || daysUntilDue < 0) {
      final absDays = daysUntilDue.abs();
      return 'Overdue by $absDays ${absDays == 1 ? 'day' : 'days'}';
    }
    if (daysUntilDue == 0) {
      return 'Due today';
    }
    if (isUpcoming) {
      return 'Due in $daysUntilDue ${daysUntilDue == 1 ? 'day' : 'days'}';
    }
    return 'Upcoming';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}



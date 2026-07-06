enum BillingCycle {
  monthly,
  quarterly,
  yearly,
  custom,
  oneTime; // NEW

  static BillingCycle fromString(dynamic value) {
    if (value == null) return BillingCycle.monthly;
    if (value is num) {
      final index = value.toInt();
      if (index >= 0 && index < BillingCycle.values.length) {
        return BillingCycle.values[index];
      }
      return BillingCycle.monthly;
    }
    final str = value.toString().toUpperCase();
    if (str == 'ONE_TIME' || str == 'ONETIME' || str == '4') return BillingCycle.oneTime;
    return BillingCycle.values.firstWhere(
      (e) => e.name.toUpperCase() == str,
      orElse: () => BillingCycle.monthly,
    );
  }

  String toJsonString() {
    if (this == BillingCycle.oneTime) return 'ONE_TIME';
    return name.toUpperCase();
  }
}

class Subscription {
  final int id;
  final String serviceName;
  final double amount;
  final BillingCycle billingCycle;
  final int? customIntervalDays;
  final String? customIntervalUnit;
  final DateTime? nextBillingDate;
  final DateTime purchaseDate;
  final bool isAutoPay;
  final String? ownerName;
  final int? ownerId;
  final String? householdName; // NEW: Based on your backend SubscriptionResponse

  final int? householdId;
  final String status;
  final bool isOverdue;
  final bool isUpcoming;
  final int daysUntilDue;
  final String? currency;


  Subscription({
    required this.id,
    required this.serviceName,
    required this.amount,
    required this.billingCycle,
    this.customIntervalDays,
    this.customIntervalUnit,
    this.nextBillingDate,
    required this.purchaseDate,
    required this.isAutoPay,
    this.ownerName,
    this.ownerId,
    this.householdName,
    this.householdId,
    this.status = 'ACTIVE',
    this.isOverdue = false,
    this.isUpcoming = false,
    this.daysUntilDue = 0,
    this.currency,
  });



  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: (json['id'] as num).toInt(),
      serviceName: (json['serviceName'] ?? '') as String,
      amount: (json['amount'] as num? ?? 0).toDouble(),
      billingCycle: BillingCycle.fromString(json['billingCycle']),
      customIntervalDays: (json['customIntervalDays'] as num?)?.toInt(),
      customIntervalUnit: json['customIntervalUnit']?.toString(),
      nextBillingDate: json['nextBillingDate'] != null ? DateTime.tryParse(json['nextBillingDate'].toString()) : null,
      purchaseDate: json['purchaseDate'] != null 
          ? (DateTime.tryParse(json['purchaseDate'].toString()) ?? DateTime.now())
          : (json['nextBillingDate'] != null ? (DateTime.tryParse(json['nextBillingDate'].toString()) ?? DateTime.now()) : DateTime.now()),
      isAutoPay: json['isAutoPay'] == true || json['isAutoPay'] == 'true' || json['isAutoPay'] == 1,
      ownerName: json['ownerName']?.toString(),
      ownerId: (json['ownerId'] as num?)?.toInt(),
      householdName: json['householdName']?.toString(),
      householdId: (json['householdId'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'ACTIVE',
      isOverdue: json['isOverdue'] == true || json['isOverdue'] == 'true' || json['isOverdue'] == 1,
      isUpcoming: json['isUpcoming'] == true || json['isUpcoming'] == 'true' || json['isUpcoming'] == 1,
      daysUntilDue: (json['daysUntilDue'] as num? ?? 0).toInt(),
      currency: json['currency']?.toString(),
    );
  }


  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'amount': amount,
        'billingCycle': billingCycle.toJsonString(),
        'customIntervalDays': customIntervalDays,
        'customIntervalUnit': customIntervalUnit,
        'nextBillingDate': nextBillingDate?.toIso8601String(),
        'purchaseDate': purchaseDate.toIso8601String(),
        'isAutoPay': isAutoPay,
        'ownerName': ownerName,
        'ownerId': ownerId,
        'householdName': householdName,
        'householdId': householdId,
        'status': status,
        'isOverdue': isOverdue,
        'isUpcoming': isUpcoming,
        'daysUntilDue': daysUntilDue,
        'currency': currency,
      };



  /// Returns a copy with updated fields.
  Subscription copyWith({
    int? id,
    String? serviceName,
    double? amount,
    BillingCycle? billingCycle,
    int? customIntervalDays,
    String? customIntervalUnit,
    DateTime? nextBillingDate,
    DateTime? purchaseDate,
    bool? isAutoPay,
    String? ownerName,
    int? ownerId,
    String? householdName,
    int? householdId,
    String? status,
    bool? isOverdue,
    bool? isUpcoming,
    int? daysUntilDue,
    String? currency,
  }) {


    return Subscription(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      customIntervalUnit: customIntervalUnit ?? this.customIntervalUnit,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isAutoPay: isAutoPay ?? this.isAutoPay,
      ownerName: ownerName ?? this.ownerName,
      ownerId: ownerId ?? this.ownerId,
      householdName: householdName ?? this.householdName,
      householdId: householdId ?? this.householdId,
      status: status ?? this.status,
      isOverdue: isOverdue ?? this.isOverdue,
      isUpcoming: isUpcoming ?? this.isUpcoming,
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
      currency: currency ?? this.currency,
    );

  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription &&
        other.id == id &&
        other.serviceName == serviceName &&
        other.amount == amount &&
        other.billingCycle == billingCycle &&
        other.customIntervalDays == customIntervalDays &&
        other.customIntervalUnit == customIntervalUnit &&
        other.nextBillingDate == nextBillingDate &&
        other.purchaseDate == purchaseDate &&
        other.isAutoPay == isAutoPay &&
        other.ownerName == ownerName &&
        other.ownerId == ownerId &&
        other.householdName == householdName &&
        other.householdId == householdId &&
        other.status == status &&
        other.isOverdue == isOverdue &&
        other.isUpcoming == isUpcoming &&
        other.daysUntilDue == daysUntilDue &&
        other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(
        id, serviceName, amount, billingCycle,
        customIntervalDays, customIntervalUnit,
        nextBillingDate, purchaseDate, isAutoPay,
        ownerName, ownerId, householdName,
        householdId, status, isOverdue, isUpcoming,
        daysUntilDue, currency,
      );
}
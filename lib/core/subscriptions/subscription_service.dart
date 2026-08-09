import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../providers/session_providers.dart';
import '../services/api_client.dart';

const String revenueCatEntitlementId = 'family_security_pro';
const String revenueCatDefaultOfferingId = 'default';
const String revenueCatMonthlyProductId = 'monthly';
const String revenueCatYearlyProductId = 'yearly';
const String revenueCatIosMonthlyProductId =
    'com.location.tracke.parental.control.monthly';
const String revenueCatIosYearlyProductId =
    'com.location.tracke.parental.control.yearly';
const List<String> revenueCatMonthlyProductIds = [
  revenueCatMonthlyProductId,
  revenueCatIosMonthlyProductId,
];
const List<String> revenueCatYearlyProductIds = [
  revenueCatYearlyProductId,
  revenueCatIosYearlyProductId,
];

/// Kept only for compatibility with existing UI code.
/// Access is no longer limited by a free-plan child count.
const int freePlanChildLimit = 1;

bool matchesRevenueCatProductId(String storeProductId, String configuredId) {
  final normalizedStoreId = storeProductId.trim();
  final normalizedConfiguredId = configuredId.trim();
  if (normalizedStoreId.isEmpty || normalizedConfiguredId.isEmpty) {
    return false;
  }
  if (normalizedStoreId == normalizedConfiguredId) {
    return true;
  }

  return normalizedStoreId.split(':').contains(normalizedConfiguredId);
}

bool matchesAnyRevenueCatProductId(
  String storeProductId,
  Iterable<String> configuredIds,
) {
  for (final configuredId in configuredIds) {
    if (matchesRevenueCatProductId(storeProductId, configuredId)) {
      return true;
    }
  }
  return false;
}

bool isRevenueCatMonthlyProductId(String storeProductId) {
  return matchesAnyRevenueCatProductId(
    storeProductId,
    revenueCatMonthlyProductIds,
  );
}

bool isRevenueCatYearlyProductId(String storeProductId) {
  return matchesAnyRevenueCatProductId(
    storeProductId,
    revenueCatYearlyProductIds,
  );
}

/// The application is fully free now, so any legacy purchase result is treated
/// as having access. This keeps old compatibility code from re-locking features.
bool isPremiumUser(CustomerInfo info) => true;

bool canAccessMultipleChildren({
  required bool isPremium,
  required int currentChildrenCount,
}) =>
    true;

bool isPremiumRequiredError(Object error) {
  if (error is! ApiException) return false;
  return error.statusCode == 403 &&
      error.message.toLowerCase().contains('premium');
}

class SubscriptionException implements Exception {
  const SubscriptionException({
    required this.message,
    this.isCancelled = false,
  });

  final String message;
  final bool isCancelled;

  @override
  String toString() => message;
}

class SubscriptionState {
  const SubscriptionState({
    this.initialized = true,
    this.configured = false,
    this.loadingOfferings = false,
    this.refreshingCustomerInfo = false,
    this.purchaseInProgress = false,
    this.restoringPurchases = false,
    this.appUserId,
    this.customerInfo,
    this.offerings,
    this.errorMessage,
  });

  final bool initialized;
  final bool configured;
  final bool loadingOfferings;
  final bool refreshingCustomerInfo;
  final bool purchaseInProgress;
  final bool restoringPurchases;
  final String? appUserId;
  final CustomerInfo? customerInfo;
  final Offerings? offerings;
  final String? errorMessage;

  /// All users have full access. No entitlement or purchase is required.
  bool get isPremium => true;

  bool get hasActiveEntitlement => true;

  Offering? get currentOffering =>
      offerings?.getOffering(revenueCatDefaultOfferingId) ?? offerings?.current;

  Package? get monthlyPackage =>
      _findPackage(currentOffering, revenueCatMonthlyProductIds) ??
      currentOffering?.monthly;

  Package? get yearlyPackage =>
      _findPackage(currentOffering, revenueCatYearlyProductIds) ??
      currentOffering?.annual;

  List<Package> get paywallPackages {
    final packages = <Package>[];

    void addPackage(Package? package) {
      if (package == null) return;
      if (package.packageType == PackageType.lifetime) return;
      if (packages.any(
        (item) => item.storeProduct.identifier == package.storeProduct.identifier,
      )) {
        return;
      }
      packages.add(package);
    }

    addPackage(yearlyPackage);
    addPackage(monthlyPackage);

    if (packages.isEmpty && currentOffering != null) {
      for (final package in currentOffering!.availablePackages) {
        addPackage(package);
      }
    }

    return packages;
  }

  SubscriptionState copyWith({
    bool? initialized,
    bool? configured,
    bool? loadingOfferings,
    bool? refreshingCustomerInfo,
    bool? purchaseInProgress,
    bool? restoringPurchases,
    String? appUserId,
    CustomerInfo? customerInfo,
    Offerings? offerings,
    String? errorMessage,
    bool clearAppUserId = false,
    bool clearCustomerInfo = false,
    bool clearOfferings = false,
    bool clearError = false,
  }) {
    return SubscriptionState(
      initialized: initialized ?? this.initialized,
      configured: configured ?? this.configured,
      loadingOfferings: loadingOfferings ?? this.loadingOfferings,
      refreshingCustomerInfo:
          refreshingCustomerInfo ?? this.refreshingCustomerInfo,
      purchaseInProgress: purchaseInProgress ?? this.purchaseInProgress,
      restoringPurchases: restoringPurchases ?? this.restoringPurchases,
      appUserId: clearAppUserId ? null : appUserId ?? this.appUserId,
      customerInfo:
          clearCustomerInfo ? null : customerInfo ?? this.customerInfo,
      offerings: clearOfferings ? null : offerings ?? this.offerings,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  static Package? _findPackage(
    Offering? offering,
    Iterable<String> productIds,
  ) {
    if (offering == null) return null;
    for (final package in offering.availablePackages) {
      if (matchesAnyRevenueCatProductId(
        package.storeProduct.identifier,
        productIds,
      )) {
        return package;
      }
    }
    return null;
  }
}

class SubscriptionService extends StateNotifier<SubscriptionState> {
  SubscriptionService() : super(const SubscriptionState());

  Future<void> bootstrap({SessionUser? user}) async {
    state = state.copyWith(
      initialized: true,
      configured: false,
      appUserId: _normalizeAppUserId(user),
      clearCustomerInfo: true,
      clearOfferings: true,
      clearError: true,
    );
  }

  Future<void> syncSessionUser(SessionUser? user) async {
    state = state.copyWith(
      initialized: true,
      configured: false,
      appUserId: _normalizeAppUserId(user),
      clearAppUserId: user == null,
      clearCustomerInfo: true,
      clearOfferings: true,
      clearError: true,
    );
  }

  /// Legacy compatibility methods intentionally do not contact RevenueCat.
  Future<Offerings?> fetchOfferings() async {
    state = state.copyWith(
      loadingOfferings: false,
      clearOfferings: true,
      clearError: true,
    );
    return null;
  }

  Future<CustomerInfo?> refreshCustomerInfo() async {
    state = state.copyWith(
      refreshingCustomerInfo: false,
      clearCustomerInfo: true,
      clearError: true,
    );
    return null;
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    state = state.copyWith(
      purchaseInProgress: false,
      clearError: true,
    );
    return null;
  }

  Future<CustomerInfo?> restorePurchases() async {
    state = state.copyWith(
      restoringPurchases: false,
      clearError: true,
    );
    return null;
  }

  Future<void> openCustomerCenter() async {
    // Purchases are disabled: there is no customer center to open.
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }

  String? _normalizeAppUserId(SessionUser? user) {
    final id = user?.id;
    if (id == null || id <= 0) return null;
    return '$id';
  }
}

final subscriptionServiceProvider =
    StateNotifierProvider<SubscriptionService, SubscriptionState>(
  (ref) => SubscriptionService(),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_providers.dart';

/// Legacy compatibility constant. There is no free-plan limit anymore.
const int freePlanChildLimit = 1;

/// Every user can add and manage any number of children from the app UI.
bool canAccessMultipleChildren({
  required bool isPremium,
  required int currentChildrenCount,
}) =>
    true;

/// Premium/paywall handling is disabled in the free version of the app.
bool isPremiumRequiredError(Object error) => false;

/// Legacy helper kept so old UI code cannot re-lock a feature.
bool isPremiumUser(Object info) => true;

class SubscriptionState {
  const SubscriptionState({
    this.initialized = true,
    this.configured = false,
    this.loadingOfferings = false,
    this.refreshingCustomerInfo = false,
    this.purchaseInProgress = false,
    this.restoringPurchases = false,
    this.appUserId,
    this.errorMessage,
  });

  final bool initialized;
  final bool configured;
  final bool loadingOfferings;
  final bool refreshingCustomerInfo;
  final bool purchaseInProgress;
  final bool restoringPurchases;
  final String? appUserId;
  final String? errorMessage;

  /// All functionality is available to every user without a purchase.
  bool get isPremium => true;

  /// Kept for compatibility with legacy callers. Access is always active.
  bool get hasActiveEntitlement => true;

  /// Billing data no longer exists. These compatibility getters stay empty.
  Object? get customerInfo => null;
  Object? get offerings => null;
  Object? get currentOffering => null;
  Object? get monthlyPackage => null;
  Object? get yearlyPackage => null;
  List<Object> get paywallPackages => const [];

  SubscriptionState copyWith({
    bool? initialized,
    bool? configured,
    bool? loadingOfferings,
    bool? refreshingCustomerInfo,
    bool? purchaseInProgress,
    bool? restoringPurchases,
    String? appUserId,
    String? errorMessage,
    bool clearAppUserId = false,
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
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// Compatibility provider for screens that used to watch subscription state.
/// It no longer initializes RevenueCat, fetches offerings, restores purchases,
/// or performs any billing-related network/platform calls.
class SubscriptionService extends StateNotifier<SubscriptionState> {
  SubscriptionService() : super(const SubscriptionState());

  Future<void> bootstrap({SessionUser? user}) async {
    state = state.copyWith(
      initialized: true,
      configured: false,
      appUserId: _normalizeAppUserId(user),
      clearAppUserId: user == null,
      clearError: true,
    );
  }

  Future<void> syncSessionUser(SessionUser? user) async {
    state = state.copyWith(
      initialized: true,
      configured: false,
      appUserId: _normalizeAppUserId(user),
      clearAppUserId: user == null,
      clearError: true,
    );
  }

  /// Legacy methods are intentionally no-ops so old callers stay safe without
  /// reintroducing billing SDKs or network calls.
  Future<Object?> fetchOfferings() async => null;
  Future<Object?> refreshCustomerInfo() async => null;
  Future<Object?> restorePurchases() async => null;
  Future<Object?> purchasePackage(Object package) async => null;
  Future<void> openCustomerCenter() async {}

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

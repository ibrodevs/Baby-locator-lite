import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/session_providers.dart';
import '../services/api_client.dart';

/// Legacy compatibility constant. There is no free-plan limit anymore.
const int freePlanChildLimit = 1;

/// Build-time key used only by Baby Locator Lite to request a signed Lite token.
/// Pass it with: --dart-define=LITE_APP_ACCESS_KEY=...
const String _liteAppAccessKey = String.fromEnvironment(
  'LITE_APP_ACCESS_KEY',
  defaultValue: '',
);

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
/// RevenueCat and billing are disabled. When a user session exists, the Lite
/// app exchanges the normal backend token for a backend-signed Lite token.
/// That keeps the paid app on its original subscription rules while this app
/// gets full server-side access without changing user.is_premium in the DB.
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

    if (user != null) {
      await _ensureLiteAccessToken();
    }
  }

  Future<void> syncSessionUser(SessionUser? user) async {
    state = state.copyWith(
      initialized: true,
      configured: false,
      appUserId: _normalizeAppUserId(user),
      clearAppUserId: user == null,
      clearError: true,
    );

    if (user != null) {
      await _ensureLiteAccessToken();
    }
  }

  Future<void> _ensureLiteAccessToken() async {
    try {
      if (_liteAppAccessKey.isEmpty) return;

      await ApiClient.instance.loadToken();
      final currentToken = ApiClient.instance.token;
      if (currentToken == null || currentToken.isEmpty) return;

      // Already exchanged for this Lite installation/session.
      if (currentToken.startsWith('lite.')) return;

      final response = await http.post(
        Uri.parse('${ApiClient.instance.baseUrl}/api/revenuecat/lite-token/'),
        headers: {
          'Authorization': 'Token $currentToken',
          'X-Lite-App-Key': _liteAppAccessKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) return;
      if (response.body.isEmpty) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;
      final liteToken = decoded['token']?.toString().trim();
      if (liteToken == null || !liteToken.startsWith('lite.')) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', liteToken);
      await ApiClient.instance.loadToken();
    } catch (_) {
      // Keep startup/login resilient. If the backend has not been deployed yet,
      // the app still opens and will retry on the next session sync/startup.
    }
  }

  /// Legacy methods are intentionally no-ops so old callers stay safe without
  /// reintroducing billing SDKs or network purchase calls.
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

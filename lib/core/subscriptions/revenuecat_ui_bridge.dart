import 'dart:async';

import 'package:flutter/material.dart';

/// Legacy compatibility types. RevenueCat UI and billing are no longer used.
typedef RevenueCatCustomerInfoCallback = FutureOr<void> Function(Object info);
typedef RevenueCatErrorCallback = void Function(String message);

const bool revenueCatUiSupported = false;

Widget buildRevenueCatPaywallView({
  required Object offering,
  required VoidCallback onDismiss,
  required RevenueCatCustomerInfoCallback onPurchaseCompleted,
  required VoidCallback onPurchaseCancelled,
  required RevenueCatErrorCallback onPurchaseError,
  required RevenueCatCustomerInfoCallback onRestoreCompleted,
  required RevenueCatErrorCallback onRestoreError,
}) {
  return const SizedBox.shrink();
}

Future<void> presentRevenueCatCustomerCenter({
  RevenueCatCustomerInfoCallback? onRestoreCompleted,
  VoidCallback? onRestoreStarted,
  RevenueCatErrorCallback? onRestoreFailed,
}) async {
  // Billing/customer-center UI was intentionally removed. All features are free.
}

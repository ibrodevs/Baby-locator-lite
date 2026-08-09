import 'package:flutter/material.dart';

/// Legacy feature identifiers kept so existing screens do not need invasive
/// changes. The app is fully free, therefore every feature is always allowed.
enum PremiumFeature {
  additionalChildren,
  liveMap,
  movementHistory,
  audioMonitoring,
  screenTime,
  appStats,
  achievements,
  loudAlarm,
  fullMenu,
  generic,
}

Future<bool> requirePremium(
  BuildContext context, {
  PremiumFeature feature = PremiumFeature.generic,
}) async {
  return true;
}

Future<bool> requirePremiumForAdditionalChild(
  BuildContext context, {
  required int currentChildrenCount,
}) async {
  return true;
}

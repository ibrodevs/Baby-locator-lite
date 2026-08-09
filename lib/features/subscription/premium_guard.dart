import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

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

/// Legacy copy helpers are retained for compatibility with any existing UI,
/// even though these features are no longer gated by a subscription.
extension PremiumFeatureCopy on PremiumFeature {
  String titleFor(BuildContext context) {
    final t = S.of(context);
    return switch (this) {
      PremiumFeature.additionalChildren => t.premiumTitleAdditionalChildren,
      PremiumFeature.liveMap => t.premiumTitleLiveMap,
      PremiumFeature.movementHistory => t.premiumTitleMovementHistory,
      PremiumFeature.audioMonitoring => t.premiumTitleAudioMonitoring,
      PremiumFeature.screenTime => t.premiumTitleScreenTime,
      PremiumFeature.appStats => t.premiumTitleAppStats,
      PremiumFeature.achievements => t.premiumTitleAchievements,
      PremiumFeature.loudAlarm => t.premiumTitleLoudAlarm,
      PremiumFeature.fullMenu => t.premiumTitleFullMenu,
      PremiumFeature.generic => t.premiumTitleGeneric,
    };
  }

  String subtitleFor(BuildContext context) {
    final t = S.of(context);
    return switch (this) {
      PremiumFeature.additionalChildren => t.premiumSubtitleAdditionalChildren,
      PremiumFeature.liveMap => t.premiumSubtitleLiveMap,
      PremiumFeature.movementHistory => t.premiumSubtitleMovementHistory,
      PremiumFeature.audioMonitoring => t.premiumSubtitleAudioMonitoring,
      PremiumFeature.screenTime => t.premiumSubtitleScreenTime,
      PremiumFeature.appStats => t.premiumSubtitleAppStats,
      PremiumFeature.achievements => t.premiumSubtitleAchievements,
      PremiumFeature.loudAlarm => t.premiumSubtitleLoudAlarm,
      PremiumFeature.fullMenu => t.premiumSubtitleFullMenu,
      PremiumFeature.generic => t.premiumSubtitleGeneric,
    };
  }
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

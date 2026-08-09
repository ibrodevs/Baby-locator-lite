import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'premium_guard.dart';

/// Compatibility screen retained for old navigation paths.
/// There is no premium onboarding anymore because all features are free.
class PremiumOnboardingScreen extends StatelessWidget {
  const PremiumOnboardingScreen({
    super.key,
    this.feature = PremiumFeature.generic,
  });

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Full access'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: AppColors.success,
              ),
              const SizedBox(height: 20),
              const Text(
                'All features are available for free',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'No subscription or in-app purchase is required.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

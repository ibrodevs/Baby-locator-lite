import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'premium_guard.dart';

/// Compatibility screen for legacy routes. Billing has been removed and the
/// screen only confirms that the requested functionality is already unlocked.
class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({
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
                Icons.lock_open_rounded,
                size: 72,
                color: AppColors.success,
              ),
              const SizedBox(height: 20),
              const Text(
                'This feature is already unlocked',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'The app is completely free. No payment or subscription is needed.',
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

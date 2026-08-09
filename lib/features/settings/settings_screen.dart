import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kid_security/l10n/app_localizations.dart';
import 'package:kid_security/l10n/app_localizations_extras.dart';

import '../../core/compliance/app_compliance.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/session_providers.dart';
import '../../core/services/device_notification_service.dart';
import '../../core/services/local_avatar_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_language_sheet.dart';
import '../../core/widgets/brand_header.dart';
import '../auth/onboarding_screen.dart';
import '../parent/children_list_screen.dart';
import 'parent_child_permissions_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationAlerts = true;
  bool _batteryAlerts = true;
  bool _safeZoneAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final settings = await DeviceNotificationService.instance.loadSettings();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = settings.pushEnabled;
      _locationAlerts = settings.locationAlerts;
      _batteryAlerts = settings.batteryAlerts;
      _safeZoneAlerts = settings.safeZoneAlerts;
    });
  }

  Future<void> _pickAvatar() async {
    if (kIsWeb) return;
    final user = ref.read(sessionProvider).user;
    if (user == null) return;

    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (xFile == null) return;

    try {
      final path = await LocalAvatarStore.instance
          .saveUserAvatar(user.id, File(xFile.path));
      if (!mounted) return;
      ref.read(sessionProvider.notifier).updateAvatar(path);
    } catch (error) {
      if (!mounted) return;
      final t = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.failedToUploadAvatar(error.toString()))),
      );
    }
  }

  NotificationSettingsModel get _currentNotificationSettings =>
      NotificationSettingsModel(
        pushEnabled: _notificationsEnabled,
        locationAlerts: _locationAlerts,
        batteryAlerts: _batteryAlerts,
        safeZoneAlerts: _safeZoneAlerts,
      );

  Future<void> _applyNotificationSettings(
    NotificationSettingsModel settings, {
    bool requestPermission = false,
  }) async {
    if (requestPermission && settings.pushEnabled) {
      final granted =
          await DeviceNotificationService.instance.ensurePermissions();
      if (!granted) {
        if (!mounted) return;
        final t = S.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.notificationPermissionRequired)),
        );
        return;
      }
    }

    await DeviceNotificationService.instance.updateSettings(settings);
    if (settings.pushEnabled) {
      await DeviceNotificationService.instance.refreshNow();
    }

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = settings.pushEnabled;
      _locationAlerts = settings.locationAlerts;
      _batteryAlerts = settings.batteryAlerts;
      _safeZoneAlerts = settings.safeZoneAlerts;
    });
  }

  Future<void> _selectLanguage() async {
    await showAppLanguageSheet(context);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppCompliance.confirmDeleteAccount(
      context,
      cascadesChildren: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(sessionProvider.notifier).deleteAccount();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        error.toString(),
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final selectedLocale = ref.watch(appLocaleProvider);
    final session = ref.watch(sessionProvider);
    final user = session.user;
    final selectedLanguageLabel = selectedLocale == null
        ? t.systemDefault
        : languageOptionFor(selectedLocale)?.nativeName ??
            selectedLocale.languageCode.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          t.settings,
          style: const TextStyle(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          AppCard(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AvatarCircle(
                        initials: (user?.displayName.isNotEmpty ?? false)
                            ? user!.displayName[0].toUpperCase()
                            : 'P',
                        color: AppColors.primary,
                        size: 80,
                        image: avatarImageProvider(user?.avatarUrl),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName.trim().isNotEmpty == true
                      ? user!.displayName
                      : t.parent,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                StatusBadge(
                  text: user?.role == UserRole.parent ? t.parent : t.child,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  ExtraL10n.of(context).tapAvatarToSet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: t.account),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.people_alt_outlined,
                  iconColor: AppColors.primary,
                  title: t.manageChildrenMenu,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChildrenListScreen(),
                    ),
                  ),
                ),
                if (user?.role == UserRole.parent) ...[
                  const Divider(
                    height: 1,
                    indent: 56,
                    color: AppColors.dividerLight,
                  ),
                  _SettingsRow(
                    icon: Icons.verified_user_outlined,
                    iconColor: AppColors.success,
                    title: ExtraL10n.of(context).childPermissionsTitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ParentChildPermissionsScreen(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: t.notifications),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsSwitchRow(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.warning,
                  title: t.pushNotifications,
                  value: _notificationsEnabled,
                  onChanged: (value) => _applyNotificationSettings(
                    _currentNotificationSettings.copyWith(pushEnabled: value),
                    requestPermission: value,
                  ),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerLight,
                ),
                _SettingsSwitchRow(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.success,
                  title: t.locationAlerts,
                  value: _locationAlerts,
                  onChanged: (value) => _applyNotificationSettings(
                    _currentNotificationSettings.copyWith(
                      locationAlerts: value,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerLight,
                ),
                _SettingsSwitchRow(
                  icon: Icons.battery_alert_outlined,
                  iconColor: AppColors.danger,
                  title: t.batteryAlerts,
                  value: _batteryAlerts,
                  onChanged: (value) => _applyNotificationSettings(
                    _currentNotificationSettings.copyWith(
                      batteryAlerts: value,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerLight,
                ),
                _SettingsSwitchRow(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.primary,
                  title: t.safeZoneAlerts,
                  value: _safeZoneAlerts,
                  onChanged: (value) => _applyNotificationSettings(
                    _currentNotificationSettings.copyWith(
                      safeZoneAlerts: value,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: t.general),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.language,
                  iconColor: AppColors.textSecondaryLight,
                  title: t.language,
                  trailingText: selectedLanguageLabel,
                  onTap: _selectLanguage,
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerLight,
                ),
                _SettingsRow(
                  icon: Icons.help_outline,
                  iconColor: AppColors.textSecondaryLight,
                  title: t.helpAndSupport,
                  onTap: () => AppCompliance.contactSupport(),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerLight,
                ),
                _SettingsRow(
                  icon: Icons.info_outline,
                  iconColor: AppColors.textSecondaryLight,
                  title: t.about,
                  onTap: () => AppCompliance.showAboutSheet(context),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerLight,
                ),
                _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.textSecondaryLight,
                  title: t.privacyPolicy,
                  onTap: () => AppCompliance.openPrivacyPolicy(),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerLight,
                ),
                _SettingsRow(
                  icon: Icons.delete_forever_outlined,
                  iconColor: AppColors.danger,
                  title: 'Delete account',
                  onTap: _deleteAccount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: true);
                await ref.read(sessionProvider.notifier).logout();
                unawaited(
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerSoft,
                foregroundColor: AppColors.danger,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                t.signOut,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              t.appVersion,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  trailingText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

/// Modal bottom sheet shown during an active ride for emergency / safety tools.
///
/// Returns `"share"` when the user taps "Share live trip", `"support"` when
/// they tap "Contact support", or `null` if dismissed.  Emergency call (911)
/// is handled directly via [url_launcher].
class InTripSafetySheet {
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.safetyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),

          _SafetyOption(
            icon: Icons.emergency_rounded,
            iconColor: Colors.white,
            iconBgColor: AppTheme.accent,
            title: context.l10n.emergencyCallTitle,
            subtitle: context.l10n.emergencyCallSubtitle,
            onTap: () async {
              HapticFeedback.heavyImpact();
              await launchUrl(Uri.parse("tel://911"));
            },
          ),
          const SizedBox(height: 10),

          _SafetyOption(
            icon: Icons.share_rounded,
            iconColor: AppTheme.accent,
            iconBgColor: AppTheme.accent.withOpacity(0.12),
            title: context.l10n.shareTripLive,
            subtitle: context.l10n.shareTripLiveSubtitle,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, "share");
            },
          ),
          const SizedBox(height: 10),

          _SafetyOption(
            icon: Icons.headset_mic_rounded,
            iconColor: AppTheme.onSurfaceMuted,
            iconBgColor: cs.surfaceContainerHighest.withOpacity(0.5),
            title: context.l10n.contactSupportDuringTrip,
            subtitle: context.l10n.contactSupportDuringTripSubtitle,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, "support");
            },
          ),
        ],
      ),
    );
  }
}

class _SafetyOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SafetyOption({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Directionality.of(context) == TextDirection.rtl
                  ? Icon(Icons.chevron_left_rounded,
                      color: AppTheme.onSurfaceMuted.withOpacity(0.5))
                  : Icon(Icons.chevron_right_rounded,
                      color: AppTheme.onSurfaceMuted.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

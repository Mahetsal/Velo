import 'package:flutter/material.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class RequestingDriverSheet extends StatelessWidget {
  final String vehicleName;
  final String vehicleSubtitle;
  final String fareText;
  final VoidCallback onCancel;

  const RequestingDriverSheet({
    super.key,
    required this.vehicleName,
    required this.vehicleSubtitle,
    required this.fareText,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.onSurface;
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.65)
        : AppTheme.onSurfaceMuted;
    final ringBgColor = isDark
        ? Colors.white.withOpacity(0.14)
        : AppTheme.onSurfaceMuted.withOpacity(0.18);
    final cardColor = isDark
        ? cs.surfaceContainerHighest.withOpacity(0.14)
        : cs.surfaceContainerHighest.withOpacity(0.75);
    final buttonBgColor = isDark
        ? cs.surfaceContainerHighest.withOpacity(0.16)
        : cs.surfaceContainerHighest;
    final buttonFgColor = isDark ? Colors.white : AppTheme.onSurface;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 8, 22, 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  backgroundColor: ringBgColor,
                  strokeWidth: 6,
                ),
                const Icon(
                  Icons.local_taxi_rounded,
                  size: 42,
                  color: AppTheme.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.findingYourDriverTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.findingYourDriverSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_taxi_rounded, color: AppTheme.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleName,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicleSubtitle,
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  fareText,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onCancel,
              style: FilledButton.styleFrom(
                backgroundColor: buttonBgColor,
                foregroundColor: buttonFgColor,
              ),
              icon: const Icon(Icons.close_rounded),
              label: Text(
                context.l10n.cancelRequest,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


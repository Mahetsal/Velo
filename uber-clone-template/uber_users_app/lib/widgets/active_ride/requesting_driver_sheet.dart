import 'package:flutter/material.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class RequestingDriverSheet extends StatelessWidget {
  final String etaMinutesText;
  final String vehicleName;
  final String vehicleSubtitle;
  final String fareText;
  final VoidCallback onCancel;

  const RequestingDriverSheet({
    super.key,
    required this.etaMinutesText,
    required this.vehicleName,
    required this.vehicleSubtitle,
    required this.fareText,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                  backgroundColor: Colors.white.withOpacity(0.14),
                  strokeWidth: 6,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      etaMinutesText,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.minUpper,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.findingYourDriverTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.findingYourDriverSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.65),
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
              color: cs.surfaceContainerHighest.withOpacity(0.14),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicleSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  fareText,
                  style: const TextStyle(
                    color: Colors.white,
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
                backgroundColor: cs.surfaceContainerHighest.withOpacity(0.16),
                foregroundColor: Colors.white,
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


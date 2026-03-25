import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class ActiveTripSheet extends StatelessWidget {
  final String tripStatusDisplay;
  final String driverName;
  final String driverPhotoUrl;
  final String carDetails;
  final String driverPhone;
  final String vehiclePlate;
  final VoidCallback onCancelTrip;
  final VoidCallback? onShareTrip;
  final VoidCallback? onEmergency;

  const ActiveTripSheet({
    super.key,
    required this.tripStatusDisplay,
    required this.driverName,
    required this.driverPhotoUrl,
    required this.carDetails,
    required this.driverPhone,
    this.vehiclePlate = "",
    required this.onCancelTrip,
    this.onShareTrip,
    this.onEmergency,
  });

  Future<void> _callDriver() async {
    if (driverPhone.trim().isEmpty) return;
    final uri = Uri.parse("tel://$driverPhone");
    await launchUrl(uri);
  }

  void _showDriverDetails(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.driverDetailsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                driverPhotoUrl.isEmpty
                    ? "https://firebasestorage.googleapis.com/v0/b/everyone-2de50.appspot.com/o/avatarman.png?alt=media&token=702d209c-9f99-46b2-832f-5bb986bc5eac"
                    : driverPhotoUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              driverName.isEmpty ? context.l10n.yourDriver : driverName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.verifiedDriver,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF34D399),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DriverDetailRow(
              icon: Icons.directions_car_rounded,
              label: context.l10n.vehicle,
              value: carDetails.isEmpty ? "—" : carDetails,
            ),
            if (vehiclePlate.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _DriverDetailRow(
                icon: Icons.confirmation_number_rounded,
                label: context.l10n.vehiclePlate,
                value: vehiclePlate.trim(),
                mono: true,
              ),
            ],
            if (driverPhone.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _DriverDetailRow(
                icon: Icons.phone_rounded,
                label: context.l10n.call,
                value: driverPhone,
              ),
            ],
            const SizedBox(height: 14),
            Text(
              context.l10n.driverVerificationNote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: driverPhone.trim().isEmpty
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        _callDriver();
                      },
                child: Text(
                  context.l10n.call,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.liveTripUpper,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tripStatusDisplay,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: context.l10n.driverDetailsTitle,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _showDriverDetails(context),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          driverPhotoUrl.isEmpty
                              ? "https://firebasestorage.googleapis.com/v0/b/everyone-2de50.appspot.com/o/avatarman.png?alt=media&token=702d209c-9f99-46b2-832f-5bb986bc5eac"
                              : driverPhotoUrl,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName.isEmpty
                                  ? context.l10n.yourDriver
                                  : driverName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              carDetails.isEmpty ? "—" : carDetails,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            if (vehiclePlate.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  vehiclePlate.trim(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF34D399),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: context.l10n.shareTrip,
                  child: FilledButton.tonal(
                    onPressed: onShareTrip == null
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            onShareTrip!();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          cs.surfaceContainerHighest.withOpacity(0.2),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      context.l10n.shareTrip,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: context.l10n.emergencyAndSupport,
                  child: FilledButton.tonal(
                    onPressed: onEmergency == null
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            onEmergency!();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          cs.surfaceContainerHighest.withOpacity(0.2),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      context.l10n.emergencyAndSupport,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: context.l10n.call,
                  child: FilledButton(
                    onPressed: driverPhone.trim().isEmpty
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            _callDriver();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          cs.surfaceContainerHighest.withOpacity(0.16),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          cs.surfaceContainerHighest.withOpacity(0.10),
                      disabledForegroundColor: Colors.white.withOpacity(0.35),
                    ),
                    child: Text(
                      context.l10n.call,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label: context.l10n.cancelTrip,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onCancelTrip();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.10),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      context.l10n.cancelTrip,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _DriverDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.onSurfaceMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: mono ? 1.6 : 0,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

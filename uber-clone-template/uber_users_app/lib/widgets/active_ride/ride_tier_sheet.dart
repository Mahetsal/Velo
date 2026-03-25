import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

class RideTierSheet extends StatelessWidget {
  final String pickupText;
  final String destinationText;
  final String selectedTier;
  final ValueChanged<String> onSelectTier;
  final String etaText;
  final Map<String, String> fareByTier;
  final String paymentLabel;
  final VoidCallback onConfirm;
  final VoidCallback onTogglePayment;
  final VoidCallback? onSelectPickupFromMap;
  final VoidCallback? onSelectDropoffFromMap;

  const RideTierSheet({
    super.key,
    required this.pickupText,
    required this.destinationText,
    required this.selectedTier,
    required this.onSelectTier,
    required this.etaText,
    required this.fareByTier,
    required this.paymentLabel,
    required this.onConfirm,
    required this.onTogglePayment,
    this.onSelectPickupFromMap,
    this.onSelectDropoffFromMap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget locationCard({
      required Color dot,
      required String label,
      required String value,
      VoidCallback? onPickFromMap,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dot.withOpacity(0.35),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(isDark ? 0.55 : 0.60),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onPickFromMap != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onPickFromMap,
                icon: const Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: AppTheme.accent,
                ),
                label: Text(
                  context.l10n.selectFromMap,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget tierTile({
      required String tier,
      required IconData icon,
      required String subtitle,
      required String price,
      required bool selected,
    }) {
      final bg = selected
          ? cs.surfaceContainerHighest.withOpacity(0.18)
          : cs.surfaceContainerHighest.withOpacity(0.10);
      final border = selected ? AppTheme.accent : Colors.transparent;
      final subtitleColor = cs.onSurface.withOpacity(isDark ? 0.60 : 0.62);
      return InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onSelectTier(tier),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: selected ? AppTheme.accent : cs.outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Velo $tier",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14, color: subtitleColor),
                        const SizedBox(width: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: subtitleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  color: selected ? AppTheme.accent : cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 4, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectVehicle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          locationCard(
            dot: AppTheme.accent,
            label: context.l10n.pickup,
            value: pickupText,
            onPickFromMap: onSelectPickupFromMap,
          ),
          const SizedBox(height: 10),
          locationCard(
            dot: Colors.white.withOpacity(0.75),
            label: context.l10n.dropoff,
            value: destinationText,
            onPickFromMap: onSelectDropoffFromMap,
          ),
          const SizedBox(height: 14),
          tierTile(
            tier: "Economy",
            icon: Icons.local_taxi_rounded,
            subtitle: etaText,
            price: fareByTier["Economy"] ?? "—",
            selected: selectedTier == "Economy",
          ),
          const SizedBox(height: 10),
          tierTile(
            tier: "Comfort",
            icon: Icons.airline_seat_recline_extra_rounded,
            subtitle: etaText,
            price: fareByTier["Comfort"] ?? "—",
            selected: selectedTier == "Comfort",
          ),
          const SizedBox(height: 10),
          tierTile(
            tier: "XL",
            icon: Icons.airport_shuttle_rounded,
            subtitle: etaText,
            price: fareByTier["XL"] ?? "—",
            selected: selectedTier == "XL",
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    color: cs.onSurface.withOpacity(isDark ? 0.85 : 0.80)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.paymentMethodUpper,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(isDark ? 0.55 : 0.60),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paymentLabel,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTogglePayment,
                style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                child: Text(
                  context.l10n.change,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB80035), Color(0xFFE11D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB80035).withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Semantics(
                button: true,
                label: context.l10n.confirmBooking,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onConfirm();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    context.l10n.confirmBooking,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


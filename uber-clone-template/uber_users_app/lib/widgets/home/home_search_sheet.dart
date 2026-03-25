import 'package:flutter/material.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';

/// "Where to?" search sheet shown in the idle phase.
///
/// Supports a compact (collapsed) and expanded mode.
/// All navigation/action is delegated to the parent via callbacks.
class HomeSearchSheet extends StatelessWidget {
  const HomeSearchSheet({
    super.key,
    required this.expanded,
    required this.userAddress,
    required this.onExpand,
    required this.onCollapse,
    required this.onSearchDestination,
    required this.onSearchPickup,
    required this.onLandmarkTap,
  });

  final bool expanded;
  final String userAddress;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onSearchDestination;
  final VoidCallback onSearchPickup;
  final VoidCallback onLandmarkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!expanded) ...[
            _CompactContent(
              onExpand: onExpand,
              onShowOptions: onExpand,
            ),
          ] else ...[
            _ExpandedContent(
              userAddress: userAddress,
              onCollapse: onCollapse,
              onSearchDestination: onSearchDestination,
              onSearchPickup: onSearchPickup,
              onLandmarkTap: onLandmarkTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({
    required this.onExpand,
    required this.onShowOptions,
  });

  final VoidCallback onExpand;
  final VoidCallback onShowOptions;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Semantics(
            button: true,
            label: context.l10n.whereTo,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onExpand,
              child: Ink(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppTheme.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.whereTo,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: onShowOptions,
              child: Text(context.l10n.showOptions),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.userAddress,
    required this.onCollapse,
    required this.onSearchDestination,
    required this.onSearchPickup,
    required this.onLandmarkTap,
  });

  final String userAddress;
  final VoidCallback onCollapse;
  final VoidCallback onSearchDestination;
  final VoidCallback onSearchPickup;
  final VoidCallback onLandmarkTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.whereTo,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: context.l10n.collapse,
                onPressed: onCollapse,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Semantics(
            button: true,
            label: context.l10n.searchDestinationHint,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onSearchDestination,
              child: Ink(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppTheme.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.searchDestinationHint,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.onSurfaceMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Icon(Icons.mic_none_rounded,
                        color: AppTheme.onSurfaceMuted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Semantics(
            button: true,
            label: '${context.l10n.pickup}: $userAddress',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onSearchPickup,
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.pickup,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Directionality.of(context) == TextDirection.rtl
                        ? const Icon(Icons.chevron_left_rounded)
                        : const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Landmarks grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _LandmarkCard(
                  icon: Icons.domain_rounded,
                  title: context.l10n.recAbdaliTitle,
                  subtitle: context.l10n.recAbdaliSubtitle,
                  priceHint: "8.2 JOD",
                  onTap: onLandmarkTap,
                ),
                _LandmarkCard(
                  icon: Icons.shopping_bag_rounded,
                  title: context.l10n.recCityMallTitle,
                  subtitle: context.l10n.recCityMallSubtitle,
                  priceHint: "4.5 JOD",
                  onTap: onLandmarkTap,
                ),
                _LandmarkCard(
                  icon: Icons.flight_takeoff_rounded,
                  title: context.l10n.airport,
                  subtitle: context.l10n.queenAliaAirport,
                  priceHint: "22 JOD",
                  onTap: onLandmarkTap,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.savings_outlined,
                          size: 18, color: AppTheme.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.alwaysCheaperTagline,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurface,
                                  ),
                        ),
                      ),
                    ],
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

class _LandmarkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String priceHint;
  final VoidCallback onTap;

  const _LandmarkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.priceHint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle, $priceHint',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.accent, size: 20),
                ),
                const Spacer(),
                Text(
                  priceHint,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.onSurfaceMuted,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    ),);
  }
}

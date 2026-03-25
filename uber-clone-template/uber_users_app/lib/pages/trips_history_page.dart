import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';
import 'package:uber_users_app/theme/app_theme.dart';
import 'package:uber_users_app/widgets/velo_skeleton.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  bool _loading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _trips = [];
  String? _uid;
  int? _filterDays = 30; // null = all time

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString("user_uid");
      _uid = uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _trips = [];
        });
        return;
      }
      final response = await ApiClient.get("/trips/by-user/$uid");
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
          _hasError = true;
          _trips = [];
        });
        return;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final items = payload["items"] as List<dynamic>? ?? [];
      setState(() {
        _loading = false;
        _trips =
            items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  DateTime? _tripDate(Map<String, dynamic> trip) {
    final raw = (trip["publishDateTime"] ??
            trip["endedAt"] ??
            trip["createdAt"] ??
            trip["timestamp"])
        ?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  List<Map<String, dynamic>> get _filteredTrips {
    final uid = _uid;
    if (uid == null) return const [];
    final now = DateTime.now();
    return _trips.where((t) {
      if (t["status"]?.toString() != "ended") return false;
      if (t["userID"]?.toString() != uid) return false;
      final days = _filterDays;
      if (days == null) return true;
      final dt = _tripDate(t);
      if (dt == null) return true; // don't hide unknown-date trips
      return now.difference(dt).inDays <= days;
    }).toList();
  }

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(context.l10n.filterAllTime),
              trailing: _filterDays == null
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(context, null),
            ),
            ListTile(
              title: Text(context.l10n.filterLast7Days),
              trailing: _filterDays == 7 ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(context, 7),
            ),
            ListTile(
              title: Text(context.l10n.filterLast30Days),
              trailing:
                  _filterDays == 30 ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(context, 30),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _filterDays = selected);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trips = _filteredTrips;
    final filterLabel =
        _filterDays == null ? context.l10n.filterAllTime : context.l10n.filterLastDays(_filterDays!);
    return Scaffold(
      body: _loading
          ? CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: cs.surface.withOpacity(0.92),
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    context.l10n.trips,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accent,
                        ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => const VeloSkeletonBlock(height: 96),
                  ),
                ),
              ],
            )
          : _hasError
          ? CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: cs.surface.withOpacity(0.92),
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    context.l10n.trips,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accent,
                        ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 48, color: AppTheme.onSurfaceMuted),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.couldNotLoadTrips,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.onSurfaceMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadTrips,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(context.l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: cs.surface.withOpacity(0.92),
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  title: Text(
                    context.l10n.trips,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accent,
                        ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: _openFilterSheet,
                      icon: const Icon(Icons.filter_list_rounded),
                      tooltip: context.l10n.filter,
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.activityLog,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.endedTrips,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            filterLabel,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (trips.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withOpacity(0.35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_car_outlined,
                                size: 36,
                                color: AppTheme.onSurfaceMuted.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.l10n.emptyTripsTitle,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.emptyTripsSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.onSurfaceMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: trips.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        final pickup = trip["pickUpAddress"]?.toString() ?? "";
                        final dropoff = trip["dropOffAddress"]?.toString() ?? "";
                        final fare = trip["fareAmount"]?.toString() ?? "0.00";
                        return _TripCard(
                          pickup: pickup,
                          dropoff: dropoff,
                          fareText: "JOD $fare",
                          onDetailsTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripDetailsPage(trip: trip),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class TripDetailsPage extends StatelessWidget {
  final Map<String, dynamic> trip;
  const TripDetailsPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String s(String key) => trip[key]?.toString() ?? "";
    final pickup = s("pickUpAddress");
    final dropoff = s("dropOffAddress");
    final fare = s("fareAmount");
    final payment = s("paymentMethod");
    final vehicle = s("vehicleType");
    final promo = s("promoCode");
    final tripId = s("tripID");
    final date = (trip["publishDateTime"] ?? trip["endedAt"] ?? "").toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tripDetailsTitle),
        backgroundColor: cs.surface.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.route,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: AppTheme.onSurfaceMuted,
                      ),
                ),
                const SizedBox(height: 10),
                _RouteTimeline(pickup: pickup, dropoff: dropoff),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _kv(context, context.l10n.fare, fare.isEmpty ? "—" : "JOD $fare"),
          _kv(context, context.l10n.payment, payment.isEmpty ? "—" : payment),
          _kv(context, context.l10n.vehicle, vehicle.isEmpty ? "—" : vehicle),
          _kv(context, context.l10n.promo, promo.isEmpty ? "—" : promo),
          _kv(context, context.l10n.tripId, tripId.isEmpty ? "—" : tripId),
          _kv(context, context.l10n.date, date.isEmpty ? "—" : date),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurfaceMuted,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                v,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String fareText;
  final VoidCallback onDetailsTap;

  const _TripCard({
    required this.pickup,
    required this.dropoff,
    required this.fareText,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    color: AppTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.trip,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.ended,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fareText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accent,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      context.l10n.paid,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: const Color(0xFF10B981),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RouteTimeline(pickup: pickup, dropoff: dropoff),
          const SizedBox(height: 14),
          Container(height: 1, color: cs.surfaceContainerLow),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.tripDetailsCta,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppTheme.accent,
                      ),
                ),
              ),
              Semantics(
                button: true,
                label: context.l10n.tripDetailsCta,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDetailsTap();
                  },
                  child: Row(
                    children: [
                      Text(context.l10n.view),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
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

class _RouteTimeline extends StatelessWidget {
  final String pickup;
  final String dropoff;
  const _RouteTimeline({required this.pickup, required this.dropoff});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PositionedDirectional(
          start: 11,
          top: 14,
          bottom: 14,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Column(
          children: [
            _TimelineRow(
              dotColor: Theme.of(context).colorScheme.surfaceContainerLow,
              label: context.l10n.pickup,
              value: pickup,
            ),
            const SizedBox(height: 12),
            _TimelineRow(
              dotColor: AppTheme.accent,
              label: context.l10n.dropoff,
              value: dropoff,
              filled: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final bool filled;
  const _TimelineRow({
    required this.dotColor,
    required this.label,
    required this.value,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: filled ? dotColor : Theme.of(context).colorScheme.outline.withOpacity(0.25),
              width: 4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: AppTheme.onSurfaceMuted,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

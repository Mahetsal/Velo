import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uber_admin_panel/core/admin_session.dart';

class Dashboard extends StatefulWidget {
  static const String id = "/dashboard";
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Future<_DashboardMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _loadMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1400 ? 4 : (width >= 1000 ? 3 : 2);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1220), Color(0xFF121E38)],
          ),
        ),
        child: FutureBuilder<_DashboardMetrics>(
          future: _metricsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Failed to load dashboard",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _metricsFuture = _loadMetrics());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            final m = snapshot.data!;
            final cards = [
              _MetricCardData("Total Drivers", m.totalDrivers.toString(), Icons.directions_car_rounded, const Color(0xFF3B82F6)),
              _MetricCardData("Total Users", m.totalUsers.toString(), Icons.groups_rounded, const Color(0xFF22C55E)),
              _MetricCardData("Completed Trips", m.completedTrips.toString(), Icons.location_on_rounded, const Color(0xFFF59E0B)),
              _MetricCardData("Total Earnings", "JOD ${m.totalEarnings.toStringAsFixed(2)}", Icons.payments_rounded, const Color(0xFFA855F7)),
              _MetricCardData("Pending Approvals", m.pendingDriverApprovals.toString(), Icons.pending_actions_rounded, const Color(0xFFFB923C)),
              _MetricCardData("Active Subscriptions", m.activeDriverSubscriptions.toString(), Icons.verified_rounded, const Color(0xFF14B8A6)),
              _MetricCardData("Inactive Subscriptions", m.inactiveDriverSubscriptions.toString(), Icons.warning_amber_rounded, const Color(0xFFEF4444)),
              _MetricCardData("Total Promos", m.totalPromos.toString(), Icons.local_offer_rounded, const Color(0xFF6366F1)),
              _MetricCardData("Active Promos", m.activePromos.toString(), Icons.check_circle_rounded, const Color(0xFF16A34A)),
              _MetricCardData("Promo Redemptions", m.promoRedemptions.toString(), Icons.insights_rounded, const Color(0xFF8B5CF6)),
            ];

            return RefreshIndicator(
              onRefresh: () async {
                final next = _loadMetrics();
                setState(() => _metricsFuture = next);
                await next;
              },
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildHero(m),
                  const SizedBox(height: 20),
                  _buildInsightStrip(m),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.8,
                    ),
                    itemBuilder: (context, index) => _buildStatCard(cards[index]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInsightStrip(_DashboardMetrics m) {
    final completionRate = m.totalDrivers == 0
        ? 0.0
        : (m.completedTrips / m.totalDrivers).clamp(0, 9999).toDouble();
    final promoRate = m.totalPromos == 0
        ? 0.0
        : (m.activePromos / m.totalPromos) * 100;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildInsightChip(
          label: "Trip/Driver ratio",
          value: completionRate.toStringAsFixed(1),
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF38BDF8),
        ),
        _buildInsightChip(
          label: "Promo activity",
          value: "${promoRate.toStringAsFixed(0)}%",
          icon: Icons.auto_graph_rounded,
          color: const Color(0xFF34D399),
        ),
        _buildInsightChip(
          label: "Pending reviews",
          value: m.pendingDriverApprovals.toString(),
          icon: Icons.fact_check_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildInsightChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70)),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(_DashboardMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Velo Operations Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Live metrics from AWS API • ${metrics.totalUsers + metrics.totalDrivers} accounts tracked",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Refresh",
            onPressed: () => setState(() => _metricsFuture = _loadMetrics()),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          const SizedBox(width: 6),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            child: Icon(Icons.shield_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_MetricCardData card) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            spreadRadius: 1,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: card.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(card.icon, color: card.color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              card.title,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              card.value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<_DashboardMetrics> _loadMetrics() async {
    final users = await _fetchEntity("users");
    final drivers = await _fetchEntity("drivers");
    final trips = await _fetchEntity("trips");
    final promos = await _fetchEntity("promos");

    final completedTrips = trips.where((t) => t["status"] == "ended").length;
    double totalEarnings = 0;
    for (final t in trips) {
      if (t["status"] == "ended") {
        totalEarnings += double.tryParse(t["fareAmount"].toString()) ?? 0.0;
      }
    }

    int pendingDriverApprovals = 0;
    int activeDriverSubscriptions = 0;
    for (final driver in drivers) {
      final approvalStatus = driver["approvalStatus"]?.toString() ?? "pending";
      if (approvalStatus != "approved") pendingDriverApprovals++;
      final sub = (driver["monthlySubscription"] ?? {}) as Map;
      if (sub["isActive"] == true) {
        activeDriverSubscriptions++;
      }
    }
    final inactiveDriverSubscriptions =
        drivers.length - activeDriverSubscriptions;

    int activePromos = 0;
    int promoRedemptions = 0;
    for (final promo in promos) {
      if (promo["isActive"] == true) activePromos++;
      promoRedemptions += int.tryParse(promo["usedCount"].toString()) ?? 0;
    }

    return _DashboardMetrics(
      totalDrivers: drivers.length,
      totalUsers: users.length,
      completedTrips: completedTrips,
      totalEarnings: totalEarnings,
      pendingDriverApprovals: pendingDriverApprovals,
      activeDriverSubscriptions: activeDriverSubscriptions,
      inactiveDriverSubscriptions: inactiveDriverSubscriptions,
      totalPromos: promos.length,
      activePromos: activePromos,
      promoRedemptions: promoRedemptions,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchEntity(String entity) async {
    final headers = await AdminSession.authHeaders();
    final response = await http.get(
      Uri.parse("${AdminSession.awsApiBaseUrl}/$entity"),
      headers: headers,
    );
    if (response.statusCode != 200) return [];
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload["items"] as List<dynamic>? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

class _MetricCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCardData(this.title, this.value, this.icon, this.color);
}

class _DashboardMetrics {
  final int totalDrivers;
  final int totalUsers;
  final int completedTrips;
  final double totalEarnings;
  final int pendingDriverApprovals;
  final int activeDriverSubscriptions;
  final int inactiveDriverSubscriptions;
  final int totalPromos;
  final int activePromos;
  final int promoRedemptions;

  const _DashboardMetrics({
    required this.totalDrivers,
    required this.totalUsers,
    required this.completedTrips,
    required this.totalEarnings,
    required this.pendingDriverApprovals,
    required this.activeDriverSubscriptions,
    required this.inactiveDriverSubscriptions,
    required this.totalPromos,
    required this.activePromos,
    required this.promoRedemptions,
  });
}
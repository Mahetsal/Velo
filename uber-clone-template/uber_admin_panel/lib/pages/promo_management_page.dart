import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_admin_panel/provider/user_provider.dart';

class PromoManagementPage extends StatefulWidget {
  static const String id = "/promoManagement";
  const PromoManagementPage({super.key});

  @override
  State<PromoManagementPage> createState() => _PromoManagementPageState();
}

class _PromoManagementPageState extends State<PromoManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _promosFuture;

  @override
  void initState() {
    super.initState();
    _promosFuture = context.read<UserProvider>().fetchPromos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _promosFuture = context.read<UserProvider>().fetchPromos();
    });
  }

  Future<void> _editPromoDialog(Map<String, dynamic> promo) async {
    final desc = TextEditingController(text: promo["description"]?.toString() ?? "");
    final value = TextEditingController(text: promo["discountValue"]?.toString() ?? "0");
    final maxCap = TextEditingController(text: promo["maxDiscountAmount"]?.toString() ?? "0");
    final type = ValueNotifier<String>((promo["discountType"] ?? "percent").toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit ${promo["code"]}"),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: type,
                builder: (_, t, __) => DropdownButtonFormField<String>(
                  value: t,
                  items: const [
                    DropdownMenuItem(value: "percent", child: Text("Percentage")),
                    DropdownMenuItem(value: "fixed", child: Text("Fixed")),
                  ],
                  onChanged: (v) => type.value = v ?? "percent",
                  decoration: const InputDecoration(labelText: "Type"),
                ),
              ),
              TextField(
                controller: value,
                decoration: const InputDecoration(labelText: "Discount Value"),
              ),
              TextField(
                controller: maxCap,
                decoration: const InputDecoration(labelText: "Max Cap (optional)"),
              ),
              TextField(
                controller: desc,
                decoration: const InputDecoration(labelText: "Description"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await context.read<UserProvider>().updatePromo(
                promo["id"].toString(),
                {
                  "discountType": type.value,
                  "discountValue": value.text.trim(),
                  "maxDiscountAmount": maxCap.text.trim().isEmpty ? "0" : maxCap.text.trim(),
                  "description": desc.text.trim(),
                },
              );
              if (!mounted) return;
              Navigator.pop(context);
              _reload();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Promo Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search promo code/description",
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _promosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final all = snapshot.data ?? [];
                  final q = _searchController.text.trim().toLowerCase();
                  final promos = all.where((p) {
                    final code = (p["code"] ?? "").toString().toLowerCase();
                    final desc = (p["description"] ?? "").toString().toLowerCase();
                    return q.isEmpty || code.contains(q) || desc.contains(q);
                  }).toList();
                  if (promos.isEmpty) return const Center(child: Text("No promos found."));

                  return ListView.builder(
                    itemCount: promos.length,
                    itemBuilder: (_, i) {
                      final promo = promos[i];
                      final active = promo["isActive"] == true;
                      final type = (promo["discountType"] ?? "percent").toString();
                      final val = promo["discountValue"]?.toString() ?? "0";
                      final cap = promo["maxDiscountAmount"]?.toString() ?? "0";
                      return Card(
                        child: ListTile(
                          title: Text("${promo["code"]}  (${active ? "Active" : "Inactive"})"),
                          subtitle: Text(
                            "$type: $val | max cap: $cap | used: ${promo["usedCount"] ?? 0} | audits: ${((promo["auditTrail"] ?? []) as List).length}\n${promo["description"] ?? ""}",
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await context.read<UserProvider>().updatePromo(
                                    promo["id"].toString(),
                                    {"isActive": !active},
                                  );
                                  _reload();
                                },
                                child: Text(active ? "Deactivate" : "Activate"),
                              ),
                              ElevatedButton(
                                onPressed: () => _editPromoDialog(promo),
                                child: const Text("Edit"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final audits =
                                      ((promo["auditTrail"] ?? []) as List);
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text("Audit - ${promo["code"]}"),
                                      content: SizedBox(
                                        width: 700,
                                        child: SingleChildScrollView(
                                          child: SelectableText(
                                            audits
                                                .map((a) => a.toString())
                                                .join("\n\n"),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("Audit"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () async {
                                  await context
                                      .read<UserProvider>()
                                      .deletePromo(promo["id"].toString());
                                  _reload();
                                },
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

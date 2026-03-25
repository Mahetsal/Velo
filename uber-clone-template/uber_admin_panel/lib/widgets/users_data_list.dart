import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uber_admin_panel/methods/common_methods.dart';
import 'package:uber_admin_panel/pages/user_data_screen.dart';
import 'package:uber_admin_panel/provider/user_provider.dart';

class UsersDataList extends StatefulWidget {
  const UsersDataList({super.key});

  @override
  State<UsersDataList> createState() => _UsersDataListState();
}

class _UsersDataListState extends State<UsersDataList> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  CommonMethods commonMethods = CommonMethods();
  final Set<String> _selectedUserIds = {};
  bool _selectAll = false;

  void _syncSelectAllState(int totalUsers) {
    setState(() {
      _selectAll = totalUsers > 0 && _selectedUserIds.length == totalUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUsers(),
      builder: (BuildContext context, snapshotData) {
        if (snapshotData.hasError) {
          return const Center(
            child: Text(
              "Error occurred. Try later",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          );
        }
        if (snapshotData.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshotData.connectionState == ConnectionState.none) {
          return const Center(
            child: Text(
              "No connection. Please check your internet.",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          );
        }

        if (!snapshotData.hasData || snapshotData.data!.isEmpty) {
          return const Center(
            child: Text(
              "No data available",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          );
        }

        final listItems = snapshotData.data!;

        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: _selectedUserIds.isEmpty
                        ? null
                        : () {
                            Provider.of<UserProvider>(context, listen: false)
                                .bulkSetUserActiveStatus(
                                    _selectedUserIds.toList(), true);
                            setState(() {});
                          },
                    child: const Text("Activate Selected"),
                  ),
                  ElevatedButton(
                    onPressed: _selectedUserIds.isEmpty
                        ? null
                        : () {
                            Provider.of<UserProvider>(context, listen: false)
                                .bulkSetUserActiveStatus(
                                    _selectedUserIds.toList(), false);
                            setState(() {});
                          },
                    child: const Text("Deactivate Selected"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Checkbox(
                    value: _selectAll,
                    onChanged: (value) {
                      setState(() {
                        _selectAll = value ?? false;
                        _selectedUserIds.clear();
                        if (_selectAll) {
                          for (final item in listItems) {
                            _selectedUserIds.add(item["id"].toString());
                          }
                        }
                      });
                    },
                  ),
                ),
                const Text("Select All"),
              ],
            ),
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 5),
              itemCount: listItems.length,
              shrinkWrap: true,
              itemBuilder: ((context, index) {
            final user = listItems[index];
            final String userId = user["id"]?.toString() ?? "";
            final bool isActive = (user["blockStatus"]?.toString() ?? "no") == "no";
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 34,
                  child: Checkbox(
                    value: _selectedUserIds.contains(userId),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedUserIds.add(userId);
                        } else {
                          _selectedUserIds.remove(userId);
                        }
                      });
                      _syncSelectAllState(listItems.length);
                    },
                  ),
                ),
                // commonMethods.data(
                //   2,
                //   Text(
                //     listItems[index]["id"].toString(),
                //   ),
                // ),
                commonMethods.data(
                  1,
                  Text(
                    user["name"]?.toString() ?? "-",
                  ),
                ),
                commonMethods.data(
                  1,
                  Text(
                    user["email"]?.toString() ?? "-",
                  ),
                ),
                commonMethods.data(
                  1,
                  Text(
                    user["phone"]?.toString() ?? "-",
                  ),
                ),
                commonMethods.data(
                  1,
                  Text(
                    "JOD ${(double.tryParse(user["walletBalance"]?.toString() ?? "0") ?? 0).toStringAsFixed(2)}",
                  ),
                ),
                commonMethods.data(
                  1,
                  Wrap(
                    spacing: 8,
                    children: [
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Provider.of<UserProvider>(context, listen: false)
                                .setUserActiveStatus(userId, !isActive);
                            setState(() {});
                          },
                          child: Text(
                            isActive ? "Deactivate" : "Activate",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserDataScreen(userId: userId),
                              ),
                            );
                          },
                          child: const Text("History"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final response = await http.get(
      Uri.parse("$_awsApiBaseUrl/users"),
      headers: {"Authorization": "Bearer public-migration-token"},
    );
    if (response.statusCode != 200) {
      return [];
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload["items"] as List<dynamic>? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

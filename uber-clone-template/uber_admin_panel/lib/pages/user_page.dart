import 'package:flutter/material.dart';
import 'package:uber_admin_panel/methods/common_methods.dart';
import 'package:uber_admin_panel/widgets/users_data_list.dart';

class UserPage extends StatefulWidget {
  static const String id = "/webPageUsers";
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  CommonMethods commonMethods = CommonMethods();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manage Users",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Wallet and account status administration",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    commonMethods.header(1, "SEL"),
                    commonMethods.header(1, "USER NAME"),
                    commonMethods.header(1, "USER EMAIL"),
                    commonMethods.header(1, "PHONE"),
                    commonMethods.header(1, "WALLET"),
                    commonMethods.header(1, "STATUS / HISTORY"),
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              UsersDataList()
            ],
          ),
        ),
      ),
    );
  }
}

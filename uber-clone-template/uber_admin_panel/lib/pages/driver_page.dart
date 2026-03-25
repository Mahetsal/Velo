import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:uber_admin_panel/methods/common_methods.dart';
import 'package:uber_admin_panel/provider/driver_provider.dart';
import 'package:uber_admin_panel/widgets/drivers_data_list.dart';

class DriverPage extends StatefulWidget {
  static const String id = "/webPageDrivers";
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  CommonMethods commonMethods = CommonMethods();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _vehicleType = "Car";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _openManualDriverDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Driver Manually"),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full name"),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  items: const [
                    DropdownMenuItem(value: "Car", child: Text("Car")),
                    DropdownMenuItem(value: "Auto", child: Text("Auto")),
                    DropdownMenuItem(value: "Bike", child: Text("Bike")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _vehicleType = value ?? "Car";
                    });
                  },
                  decoration: const InputDecoration(labelText: "Vehicle Type"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty ||
                    _emailController.text.trim().isEmpty ||
                    _phoneController.text.trim().isEmpty) {
                  return;
                }
                try {
                  await Provider.of<DriverProvider>(context, listen: false)
                      .createDriverManually(
                    fullName: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                    vehicleType: _vehicleType,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  _nameController.clear();
                  _emailController.clear();
                  _phoneController.clear();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Manage Drivers",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Approval, activation and subscription controls",
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _openManualDriverDialog,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text("Add Driver"),
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
                    commonMethods.header(1, "NAME"),
                    commonMethods.header(1, "CAR DETAILS"),
                    commonMethods.header(1, "PHONE"),
                    commonMethods.header(1, "EARNING / STATUS"),
                    commonMethods.header(1, "APPROVAL / ACTIVATION / SUB"),
                    commonMethods.header(1, "VIEW MORE"),
                  ],
                ),
              ),
              const SizedBox(

                
                height: 12,
              ),
              const DriversDataList(),
            ],
          ),
        ),
      ),
    );
  }
}

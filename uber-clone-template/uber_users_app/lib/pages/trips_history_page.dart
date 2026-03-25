import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  static const String _awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";
  bool _loading = true;
  List<Map<String, dynamic>> _trips = [];
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("user_uid");
    _uid = uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _trips = [];
      });
      return;
    }
    final response =
        await http.get(Uri.parse("$_awsApiBaseUrl/trips/by-user/$uid"));
    if (response.statusCode != 200) {
      setState(() {
        _loading = false;
        _trips = [];
      });
      return;
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = payload["items"] as List<dynamic>? ?? [];
    setState(() {
      _loading = false;
      _trips = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'My Trips History',
          style: TextStyle(
            color: Colors.black,
          ),
          
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const Center(
                  child: Text(
                    "No record found.",
                    style: TextStyle(color: Colors.black),
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(5),
              shrinkWrap: true,
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                if (_trips[index]["status"] != null &&
                    _trips[index]["status"] == "ended" &&
                    _trips[index]["userID"] == _uid) {
                  return Card(
                    color: Colors.white,
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup - fare amount
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/initial.png',
                                height: 16,
                                width: 16,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Text(
                                  _trips[index]["pickUpAddress"].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    //color: Colors.white38,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "JOD ${_trips[index]["fareAmount"]}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Dropoff
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/final.png',
                                height: 16,
                                width: 16,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Text(
                                  _trips[index]["dropOffAddress"].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    //color: Colors.white38,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
    );
  }
}

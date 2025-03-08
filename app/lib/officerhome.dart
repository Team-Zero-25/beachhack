import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferoute/login.dart';
import 'package:saferoute/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'sosmapscreen.dart';

class OfficerHome extends StatefulWidget {
  final String officerName;
  final String officerPhone;
  const OfficerHome(
      {super.key, required this.officerName, required this.officerPhone});

  @override
  State<OfficerHome> createState() => _OfficerHomeState();
}

class _OfficerHomeState extends State<OfficerHome> {
  String loc = "Fetching location...";
  double? lat, long;
  Timer? _timer;
  List<Map<String, dynamic>> sosAlerts = [];

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _fetchSOSAlerts();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchSOSAlerts();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    setState(() {
      lat = 9.514985;
      long = 76.831329;
      loc = "📍 (${lat}, ${long})";
    });
  }
//9.514985, 76.831329

  Future<void> _fetchSOSAlerts() async {
    final String apiUrl =
        // "/sos/currentAlert?latitude=$lat&longitude=$long";
        "http://127.0.0.1:8888/sos/currentAlert?latitude=$lat&longitude=$long";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse["status"] == "success") {
          final List<dynamic> data = jsonResponse["data"] ?? [];

          setState(() {
            sosAlerts = data.map((sos) {
              return {
                "email": sos["email"] ?? "Unknown",
                "lat": (sos["latitude"] as num?)?.toDouble() ?? 0.0,
                "long": (sos["longitude"] as num?)?.toDouble() ?? 0.0,
                "ack": sos["ack"] ?? false,
              };
            }).toList();
          });
        }
      } else {
        throw Exception("Failed to load alerts");
      }
    } catch (error) {
      print("Error fetching SOS alerts: $error");
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  Future<void> _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  Future<void> _acknowledgeSOS(String email) async {
    final String apiUrl =
        // "/sos/acknowledge";
        "http://127.0.0.1:8888/sos/acknowledge";

    try {
      print(email);
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'ack': 'true',
          'officerName': widget.officerName,
          'officerPhone': widget.officerPhone,
        }),
      );

      if (response.statusCode == 200) {
        print("SOS acknowledged successfully");
      } else {
        throw Exception("Failed to acknowledge SOS");
      }
    } catch (error) {
      print("Error acknowledging SOS: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "SafeRoute - Officer",
          style: GoogleFonts.poppins(fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard("👮 Officer", widget.officerName, Colors.black),
            const SizedBox(height: 16),
            _buildInfoCard("📍 Current Location", loc, Colors.black),
            const SizedBox(height: 20),
            Text(
              "🚨 SOS Alerts",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: sosAlerts.isEmpty
                  ? Center(
                      child: Text(
                        "No active SOS alerts",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sosAlerts.length,
                      itemBuilder: (context, index) {
                        final sos = sosAlerts[index];
                        double distance = lat != null && long != null
                            ? _calculateDistance(
                                lat!, long!, sos["lat"], sos["long"])
                            : 0.0;
                        return _buildSOSCard(
                          sos["email"],
                          lat != null && long != null
                              ? "${distance.toStringAsFixed(2)} km away"
                              : "Calculating...",
                          () async {
                            if (lat == null || long == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Location not available yet. Please wait."),
                                ),
                              );
                              return;
                            }

                            await _acknowledgeSOS(sos["email"]);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SOSMapPage(
                                  officerLat: lat!,
                                  officerLong: long!,
                                  sosLat: sos["lat"],
                                  sosLong: sos["long"],
                                  sosLocation: sos["email"],
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

  Widget _buildInfoCard(String title, String value, Color color) {
    return Card(
      color: color,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSCard(String location, String distance, VoidCallback onTap) {
    return Card(
      color: Colors.redAccent,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(
          location,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          distance,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
          child: Text(
            "ACK",
            style: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

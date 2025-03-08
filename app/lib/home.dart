import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'route_planner.dart';
import 'services/location_services.dart';
import 'stillmap.dart';
import 'sos_active.dart';
import 'rest.dart';
import 'accounts.dart';
import 'call.dart';
import 'room.dart';
import 'camera_screen.dart'; // Import the CameraScreen

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String loc = "Fetching location...";
  var lat = 9.5286;
  var long = 76.8235;
  bool isSosActive = false;
  StreamSubscription<Position>? _locationStreamSubscription;
  Timer? _acknowledgmentTimer;
  bool _isAcknowledged = false; // State variable for acknowledgment status

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _startAcknowledgmentCheck();
  }

  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    _acknowledgmentTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationStreamSubscription = LocationService.locationStream.listen(
      (Position position) {
        setState(() {
          lat = position.latitude;
          long = position.longitude;
          loc = "Lat: ${position.latitude}, Lng: ${position.longitude}";
        });
      },
      onError: (error) {
        setState(() {
          loc = "Error: $error";
        });
      },
    );
    LocationService.startLocationTracking();
  }

  void _startAcknowledgmentCheck() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email') ?? "user@example.com";

    // Check acknowledgment every 5 seconds
    _acknowledgmentTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkSosAcknowledgment(email);
    });
  }

  Future<void> _checkSosAcknowledgment(String email) async {
    try {
      final response = await Api.check_sos_acknowledgment(email: email);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Check if the status is "success" and extract the `ack` value from the `data` field
        if (jsonResponse["status"] == "success") {
          bool ack = jsonResponse["data"]["ack"] ?? false;
          String officerPhone = jsonResponse["data"]["officerPhone"] ?? "";
          String officerName = jsonResponse["data"]["officerName"] ?? "";

          if (ack && !_isAcknowledged) {
            SosAcknowledgmentData().setOfficerPhone(officerPhone, officerName);
            setState(() {
              _isAcknowledged = true;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'SOS acknowledged! Help is on the way.',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (!ack && _isAcknowledged) {
            // Clear the acknowledgment message if `ack` is false
            setState(() {
              _isAcknowledged = false;
            });
          }
        } else {
          print('Error: ${jsonResponse["message"]}');
        }
      } else {
        print('Error checking SOS acknowledgment: ${response.body}');
      }
    } catch (e) {
      print('Error checking SOS acknowledgment: $e');
    }
  }

  void _toggleSos() async {
    try {
      bool newStatus = !isSosActive; // Toggle status
      SosActive().updateSos(newStatus); // Update the singleton

      setState(() {
        isSosActive = newStatus;
      });

      // Retrieve the email from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String email = prefs.getString('email') ?? "user@example.com";

      if (newStatus) {
        // Send SOS to the backend with the current location and email
        final response =
            await Api.send_sos(latitude: lat, longitude: long, email: email);

        if (response.statusCode == 200) {
          print('SOS sent successfully');
        } else {
          print('Error sending SOS: ${response.body}');
        }
      } else {
        // Deactivate SOS by sending a DELETE request to the backend
        final response = await Api.deactivate_sos(email: email);

        if (response.statusCode == 200) {
          print('SOS deactivated successfully');
        } else {
          print('Error deactivating SOS: ${response.body}');
        }
      }
    } catch (e) {
      print('Error sending SOS: $e');
    }
  }

  int _selectedIndex = 0;

  List<Widget> _widgetOptions(String loc) => <Widget>[
        HomeWidget(
          lat: lat,
          long: long,
          isSosActive: isSosActive,
          onSosPressed: _toggleSos,
          isAcknowledged: _isAcknowledged,
        ),
        RoutePlanner(),
        AccountPage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Handle menu button press
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_sharp, color: Colors.black),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Call()));
            },
          ),
        ],
        title: Text(
          'SafeRoute',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions(loc),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color(0x00000000),
        height: 50,
        color: const Color(0xFF3D3D3D),
        buttonBackgroundColor: const Color(0xFF3D3D3D),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.map, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        onTap: _onItemTapped,
        index: _selectedIndex,
      ),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({
    super.key,
    required this.lat,
    required this.long,
    required this.isSosActive,
    required this.onSosPressed,
    required this.isAcknowledged,
  });

  final dynamic lat;
  final dynamic long;
  final bool isSosActive;
  final VoidCallback onSosPressed;
  final bool isAcknowledged;

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isSosActive) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HomeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSosActive != oldWidget.isSosActive) {
      if (widget.isSosActive) {
        _animationController.repeat(reverse: true); // Start animation
      } else {
        _animationController.stop(); // Stop animation
        _animationController.reverse(); // Return to original size
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  '📍: Lat: ${widget.lat}, Lng: ${widget.long}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  surfaceTintColor: Colors.black,
                  color: Colors.black,
                  clipBehavior: Clip.antiAlias,
                  elevation: 10,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: MapWidget(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Home Page',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.isSosActive)
                    RotationTransition(
                      turns: _animationController,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: widget.isSosActive ? 100 : 80,
                      height: widget.isSosActive ? 100 : 80,
                      decoration: BoxDecoration(
                        color: widget.isSosActive ? Colors.red : Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: widget.onSosPressed,
                          child: Center(
                            child: Text(
                              'SOS',
                              style: GoogleFonts.poppins(
                                fontSize: widget.isSosActive ? 24 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.isSosActive ? 'SOS Active' : 'SOS Inactive',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: widget.isSosActive ? Colors.red : Colors.green,
                    ),
                  ),
                  if (widget
                      .isAcknowledged) // Show acknowledgment message only if `_isAcknowledged` is true
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'SOS acknowledged! Help is on the way.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SafeAreasPage(
                                  // Navigate to the Safe Areas page
                                  latitude: widget.lat,
                                  longitude: widget.long,
                                )));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Take rest?',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NearbyRoomsPage(
                                    // Navigate to the Room page
                                    latitude: widget.lat,
                                    longitude: widget.long,
                                  )));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Looking for stay?',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // Add the Camera Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CameraScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Open Camera',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SosAcknowledgmentData {
  static final SosAcknowledgmentData _instance =
      SosAcknowledgmentData._internal();

  factory SosAcknowledgmentData() => _instance;

  SosAcknowledgmentData._internal();
  String? officerName;
  String? officerPhone;

  void setOfficerPhone(String phone, String name) {
    officerPhone = phone;
    officerName = name;
  }

  String? getOfficerPhone() {
    return officerPhone;
  }

  String? getOfficerName() {
    return officerName;
  }
}

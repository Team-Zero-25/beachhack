import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'consts.dart';
import 'api.dart';

class RoutePlanner extends StatefulWidget {
  const RoutePlanner({Key? key}) : super(key: key);

  @override
  State<RoutePlanner> createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner> {
  loc.Location _locationController = loc.Location();
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentP;
  LatLng? _startLocation;
  LatLng? _destinationLocation;
  Map<PolylineId, Polyline> polylines = {};
  Set<Marker> markers = {};
  Set<Circle> circles = {}; // Store circles for zones
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  List<dynamic> zones = []; // Store fetched zones
  StreamSubscription<loc.LocationData>?
      _locationSubscription; // Stream subscription for location updates

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
    fetchZones(); // Fetch zones from MongoDB
  }

  @override
  void dispose() {
    _locationSubscription?.cancel(); // Cancel the stream subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white10, // Matte black background
      // appBar: AppBar(
      //   title: const Text(
      //     "Route Planner",
      //     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      //   ),
      //   backgroundColor: Colors.black, // Matte black app bar
      //   elevation: 0, // Remove shadow
      //   iconTheme: IconThemeData(color: Colors.white), // White icons
      // ),
      body: Column(
        children: [
          // Modern Art Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white10, // Black background
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Center(
              child: Text(
                "Plan Your Route",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          // Input Fields
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTextField(_startController, "Enter Start Location"),
                const SizedBox(height: 16),
                _buildTextField(_destinationController, "Enter Destination"),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _setRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Matte white button
                    foregroundColor: Colors.white, // Black text
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4, // Subtle shadow
                  ),
                  child: const Text(
                    "Show Route",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Map Section
          Expanded(
            child: _currentP == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white, // White loading indicator
                    ),
                  )
                : GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController.complete(controller);
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentP ??
                          LatLng(0, 0), // Fallback to a default location
                      zoom: 12,
                    ),
                    markers: markers, // Show only start and destination markers
                    circles: circles, // Show circles for zones
                    polylines: Set<Polyline>.of(polylines.values),
                  ),
          ),
        ],
      ),
    );
  }

  // Custom TextField Widget
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
        controller: controller,
        style: TextStyle(color: Colors.black), // White text
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]), // Grey label
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
        ));
  }

  Future<void> _setRoute() async {
    _startLocation = await _getCoordinatesFromAddress(_startController.text);
    _destinationLocation =
        await _getCoordinatesFromAddress(_destinationController.text);

    if (_startLocation != null && _destinationLocation != null) {
      // Add start and destination markers
      setState(() {
        markers = {
          Marker(
            markerId: MarkerId("start"),
            position: _startLocation!,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
          Marker(
            markerId: MarkerId("destination"),
            position: _destinationLocation!,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });

      getPolylinePoints().then((coordinates) {
        generatePolyLineFromPoints(coordinates);
        _checkRouteForZones(coordinates); // Check if zones are on the route
      });
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("Geocoding Error: $e");
    }
    return null;
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) return;
    }

    loc.PermissionStatus _permissionGranted =
        await _locationController.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) return;
    }

    // Store the subscription
    _locationSubscription = _locationController.onLocationChanged
        .listen((loc.LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        if (mounted) {
          // Check if the widget is still mounted
          setState(() {
            _currentP =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
          });
        }
      }
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: GOOGLE_MAPS_API_KEY,
      request: PolylineRequest(
        origin:
            PointLatLng(_startLocation!.latitude, _startLocation!.longitude),
        destination: PointLatLng(
            _destinationLocation!.latitude, _destinationLocation!.longitude),
        mode: TravelMode.driving,
      ),
    );
    if (result.points.isNotEmpty) {
      polylineCoordinates.addAll(result.points
          .map((point) => LatLng(point.latitude, point.longitude)));
    }
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("route");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent, // Bright blue polyline
      points: polylineCoordinates,
      width: 5,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }

  // Fetch zones from API
  Future<void> fetchZones() async {
    try {
      // final response = await http.get(Uri.parse('/alert/zone'));
      final response =
          await http.get(Uri.parse('http://127.0.0.1:8888/alert/zone'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Zones fetched successfully: ${data['data']}"); // Debug log
        setState(() {
          zones = data['data']; // Store zones
        });
      } else {
        print("Error fetching zones: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  // Check if zones are on or near the route
  void _checkRouteForZones(List<LatLng> routeCoordinates) {
    Set<Circle> newCircles = {};

    for (var zone in zones) {
      double lat = zone["latitude"];
      double lng = zone["longitude"];
      int count = zone["count"];

      // Check if the zone is near the route
      bool isOnRoute = _isPointNearRoute(LatLng(lat, lng), routeCoordinates);

      if (isOnRoute) {
        print("Zone on route: ($lat, $lng)"); // Debug log
        // Choose circle color based on count
        Color circleColor;
        if (count > 10) {
          circleColor = Colors.red.withOpacity(0.3); // Dangerous
        } else if (count > 5) {
          circleColor = Colors.yellow.withOpacity(0.3); // Moderately Risky
        } else {
          circleColor = Colors.green.withOpacity(0.3); // Safe
        }

        newCircles.add(
          Circle(
            circleId: CircleId("$lat,$lng"),
            center: LatLng(lat, lng),
            radius: 500, // Increase radius to 500 meters
            strokeWidth: 2,
            strokeColor: circleColor.withOpacity(1),
            fillColor: circleColor,
          ),
        );
      }
    }

    if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        circles = newCircles; // Update circles
      });
    }
  }

  // Check if a point is near the route
  bool _isPointNearRoute(LatLng point, List<LatLng> routeCoordinates,
      {double threshold = 010}) {
    for (var coord in routeCoordinates) {
      double distance = _calculateDistance(point, coord);
      if (distance <= threshold) {
        return true;
      }
    }
    return false;
  }

  // Calculate distance between two LatLng points
  double _calculateDistance(LatLng p1, LatLng p2) {
    double lat1 = p1.latitude;
    double lon1 = p1.longitude;
    double lat2 = p2.latitude;
    double lon2 = p2.longitude;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return 6371 * c; // Distance in kilometers
  }
}

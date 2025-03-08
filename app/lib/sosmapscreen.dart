import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'consts.dart';

class SOSMapPage extends StatefulWidget {
  final double officerLat, officerLong, sosLat, sosLong;
  final String sosLocation;

  const SOSMapPage({
    super.key,
    required this.officerLat,
    required this.officerLong,
    required this.sosLat,
    required this.sosLong,
    required this.sosLocation,
  });

  @override
  State<SOSMapPage> createState() => _SOSMapPageState();
}

class _SOSMapPageState extends State<SOSMapPage> {
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  /// Fetches the route from the Google Maps Directions API
  void _fetchRoute() async {
    const String apiKey = GOOGLE_MAPS_API_KEY; // Replace with your API key
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${widget.officerLat},${widget.officerLong}&"
        "destination=${widget.sosLat},${widget.sosLong}&"
        "key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "OK") {
          final points = _decodePolyline(data["routes"][0]["overview_polyline"]["points"]);
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId("route"),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            };
            _isLoading = false;
          });
        } else {
          throw Exception("Failed to fetch route: ${data["status"]}");
        }
      } else {
        throw Exception("Failed to load directions");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Decodes the polyline points from the API response
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SOS Location - ${widget.sosLocation}")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.officerLat, widget.officerLong),
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId("officer"),
                position: LatLng(widget.officerLat, widget.officerLong),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                infoWindow: const InfoWindow(title: "Officer"),
              ),
              Marker(
                markerId: const MarkerId("sos"),
                position: LatLng(widget.sosLat, widget.sosLong),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: widget.sosLocation),
              ),
            },
            polylines: _polylines,
            onMapCreated: (controller) => _mapController = controller,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
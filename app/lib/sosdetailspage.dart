import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SOSDetailsPage extends StatefulWidget {
  final double officerLat;
  final double officerLong;
  final double sosLat;
  final double sosLong;
  final String sosLocation;

  const SOSDetailsPage({
    super.key,
    required this.officerLat,
    required this.officerLong,
    required this.sosLat,
    required this.sosLong,
    required this.sosLocation,
  });

  @override
  State<SOSDetailsPage> createState() => _SOSDetailsPageState();
}

class _SOSDetailsPageState extends State<SOSDetailsPage> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: const MarkerId("officer"),
        position: LatLng(widget.officerLat, widget.officerLong),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "Officer"),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId("sos"),
        position: LatLng(widget.sosLat, widget.sosLong),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.sosLocation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Details")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.officerLat, widget.officerLong),
          zoom: 12,
        ),
        markers: _markers,
        onMapCreated: (controller) => _controller = controller,
      ),
    );
  }
}

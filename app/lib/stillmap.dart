import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  Position? _currentPosition;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  Map<String, Map<String, dynamic>> redZones = {};
  static const String _storageKey = 'additional_red_zones';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAllRedZones();
  }

  Future<void> _loadAllRedZones() async {
    await _loadInitialRedZones();
    await _loadAdditionalRedZones();
    _createCirclesAndMarkers();
  }

  Future<void> _loadInitialRedZones() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/dummy-redzone.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      setState(() {
        redZones = Map<String, Map<String, dynamic>>.from(
          jsonData.map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value))),
        );
      });
    } catch (e) {
      debugPrint('Error loading initial red zones: $e');
    }
  }

  Future<void> _loadAdditionalRedZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? additionalZonesJson = prefs.getString(_storageKey);

      if (additionalZonesJson != null) {
        final Map<String, dynamic> additionalZones =
            json.decode(additionalZonesJson);
        setState(() {
          redZones.addAll(
            Map<String, Map<String, dynamic>>.from(
              additionalZones.map((key, value) =>
                  MapEntry(key, Map<String, dynamic>.from(value))),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading additional red zones: $e');
    }
  }

  Future<void> _saveAdditionalRedZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only save the newly added zones
      final initialZones = await _loadInitialRedZonesAsMap();
      final additionalZones = Map<String, dynamic>.from(redZones)
        ..removeWhere((key, value) => initialZones.containsKey(key));

      await prefs.setString(_storageKey, json.encode(additionalZones));
    } catch (e) {
      debugPrint('Error saving additional red zones: $e');
    }
  }

  Future<Map<String, dynamic>> _loadInitialRedZonesAsMap() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/dummy-redzone.json');
      return json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading initial red zones map: $e');
      return {};
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            12,
          ),
        );
      }
    });
  }

  void _createCirclesAndMarkers() {
    Set<Circle> circles = {};
    Set<Marker> markers = {};

    redZones.forEach((key, value) {
      final LatLng position = LatLng(value['lat'], value['long']);

      circles.add(
        Circle(
          circleId: CircleId(key),
          center: position,
          radius: 500, // 500 meters radius
          fillColor: Colors.red.withOpacity(0.3),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ),
      );

      markers.add(
        Marker(
          markerId: MarkerId(key),
          position: position,
          infoWindow: InfoWindow(
            title: key,
            snippet: value['issue'],
          ),
        ),
      );
    });

    setState(() {
      _circles = circles;
      _markers = markers;
    });
  }

  Future<void> _showAddMarkerDialog(LatLng position) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController issueController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Red Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name',
                hintText: 'Enter location name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: issueController,
              decoration: const InputDecoration(
                labelText: 'Issue',
                hintText: 'Describe the issue',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  issueController.text.isNotEmpty) {
                setState(() {
                  redZones[nameController.text] = {
                    'lat': position.latitude,
                    'long': position.longitude,
                    'issue': issueController.text,
                  };
                });
                _createCirclesAndMarkers();
                await _saveAdditionalRedZones();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(_currentPosition);
    return SizedBox(
      height: 300,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 12,
        ),
        onMapCreated: (controller) {
          setState(() {
            _controller = controller;
          });
        },
        onTap: (LatLng position) {
          _showAddMarkerDialog(position);
        },
        circles: _circles,
        markers: {
          ..._markers,
          if (_currentPosition != null)
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: const InfoWindow(
                title: 'Your Location',
              ),
            ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}

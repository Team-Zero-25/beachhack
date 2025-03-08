import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:saferoute/api.dart'; // Import your API service to send requests

class LocationService {
  static StreamController<Position> _locationStreamController = StreamController<Position>.broadcast();
  static StreamSubscription<Position>? _locationStreamSubscription;

  // Getter for the location stream
  static Stream<Position> get locationStream => _locationStreamController.stream;

  // Request location permissions
  static Future<bool> getLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever.');
        return false;
      }
      return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
    } catch (e) {
      print('Error checking/requesting location permission: $e');
      return false;
    }
  }

  // Start location stream updates
  static Future<void> startLocationTracking() async {
    bool permission = await getLocationPermission();
    if (!permission) return;

    // Start location stream with optimized settings
    _locationStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // Use appropriate accuracy
        distanceFilter: 50, // Update every 50 meters to reduce battery usage
        // timeInterval: 30000, // Update every 30 seconds
      ),
    ).listen((Position position) {
      // Emit the position update through the stream
      _locationStreamController.add(position);

      // Send the location to the backend after getting a valid position
      _sendLocationToBackend(position);
    }, onError: (error) {
      print('Error in location stream: $error');
    });
  }

  // Start background location tracking
  static Future<void> startBackgroundTracking() async {
    bool permission = await getLocationPermission();
    if (!permission) return;

    // Start foreground service for background location tracking
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: "SafeRoute Location Tracking",
        notificationText: "Your location is being tracked in the background.",
        callback: locationCallback,
      );

      // Start location tracking in the background
      startLocationTracking();
    } catch (e) {
      print('Error starting foreground service: $e');
    }
  }

  // Stop background location tracking
  static void stopBackgroundTracking() {
    _locationStreamSubscription?.cancel(); // Cancel the location stream
    _locationStreamController.close(); // Close the stream controller
    FlutterForegroundTask.stopService(); // Stop the foreground service
  }

  // Function to send location data to backend
  static Future<void> _sendLocationToBackend(Position position) async {
    print('-->> ${position.latitude}, ${position.longitude}');
    try {
      await Api.current_location(
        latitude: position.latitude,
        longitude: position.longitude,
      );

    } catch (e) {
      print('Error sending location: $e');
    }
  }
}

// Background callback function for location tracking
@pragma('vm:entry-point')
void locationCallback() {
  LocationService.startLocationTracking();
}
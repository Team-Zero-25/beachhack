import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:saferoute/notification.dart';

// final BASE_URL = 'http://localhost:8080';
// final BASE_URL = '';
final BASE_URL = 'http://127.0.0.1:8888';
StreamSubscription? _currentStreamSubscription;
// final BASE_URL = 'http://192.168.43.234:8080';
var client = http.Client();

class Api {
  static Future<http.Response> registerUser({
    required String email,
    required String name,
    required String phone,
    required String password,
    required String usertype,
  }) async {
    final response = await client.post(
      Uri.parse('$BASE_URL/user/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
        'name': name,
        'phone_number': phone,
        'password': password,
        'usertype': usertype,
      }),
    );
    print(response.body);

    return response;
  }

  static Future<http.Response> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse('$BASE_URL/user/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    print(response.body);
    return response;
  }

  static String? _lastZone; // Store last detected zone

  static current_location({
    required double latitude,
    required double longitude,
  }) async {
    // Cancel the previous stream if it exists
    _currentStreamSubscription?.cancel();

    final uri =
        Uri.parse('$BASE_URL/sse?latitude=$latitude&longitude=$longitude');
    final request = http.Request('GET', uri)
      ..headers
          .addAll({'Accept': 'text/event-stream'}); // Specify SSE response type

    // Establish the SSE connection
    final response = await client.send(request);
    print("HELLO DEER");
    final stream = response.stream;

    // Listen for incoming events
    _currentStreamSubscription = stream.listen(
      (chunk) {
        final event = utf8.decode(chunk).trim(); // Decode and process event
        print('EVR: $event');

        if (event.startsWith('data: ')) {
          final message = event.substring(6).trim(); // Remove "data: " part
          print("Message: $message");

          String? currentZone;

          // Extract zone information
          if (message.contains("red zone")) {
            currentZone = "🚨 Red Zone (>10)";
          } else if (message.contains("yellow zone")) {
            currentZone = "⚠️ Yellow Zone (>5)";
          } else if (message.contains("green zone")) {
            currentZone = "✅ Green Zone (<5)";
          } else if (message.contains("white zone")) {
            currentZone = "⚪ White Zone";
          }

          // Send notification **only if zone has changed**
          if (currentZone != null && currentZone != _lastZone) {
            NotificationService.showNotification("Zone Alert", currentZone);
            _lastZone = currentZone; // Update last zone
          }
        }
      },
      onError: (error) {
        print('Error: $error');
      },
      onDone: () {
        print('Stream closed');
      },
    );

    return;
  }

  static Future<http.Response> send_sos(
      {required double latitude,
      required double longitude,
      required String email}) async {
    final response = await client.post(
      Uri.parse('$BASE_URL/sos/send_sos'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'email': email,
      }),
    );
    return response;
  }

  static Future<http.Response> deactivate_sos({required String email}) async {
    final response = await client.post(
      Uri.parse('$BASE_URL/sos/delete_sos'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
      }),
    );
    return response;
  }

  static Future<http.Response> check_sos_acknowledgment(
      {required String email}) async {
    // final String apiUrl = "/sos/checkAcknowledgment?email=$email";
    final String apiUrl = "";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("ack${response.body}");
      return response;
    } catch (e) {
      print("Error checking SOS acknowledgment: $e");
      rethrow;
    }
  }
}

class ZoneData {
  static String currentZone = "Unknown Zone";

  static void updateZone(String zone) {
    currentZone = zone;
  }
}

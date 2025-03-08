import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SafeAreasPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const SafeAreasPage(
      {super.key, required this.latitude, required this.longitude});

  @override
  _SafeAreasPageState createState() => _SafeAreasPageState();
}

class _SafeAreasPageState extends State<SafeAreasPage> {
  Position? _currentPosition;
  List<dynamic> _safeAreas = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, String> _userVotes =
      {}; // Stores user votes ("upvote", "downvote")

  @override
  void initState() {
    super.initState();
    _currentPosition = Position(
      latitude: widget.latitude,
      longitude: widget.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<void> _fetchSafeAreas() async {
    if (_currentPosition == null) {
      setState(() {
        _errorMessage = 'Location not available yet.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        // Uri.parse('/safezone/fetch?latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}'),
        Uri.parse(
            'http://127.0.0.1:8888/safezone/fetch?latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          setState(() {
            _safeAreas = data['data'];
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to fetch safe areas: ${data["message"]}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch safe areas. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching safe areas: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _vote(String areaName, String voteType) {
    setState(() {
      if (_userVotes[areaName] == voteType) {
        _userVotes.remove(areaName);
        if (voteType == "upvote") {
          _safeAreas.firstWhere((area) => area['Name'] == areaName)['upvote'] -=
              1;
        } else {
          _safeAreas
              .firstWhere((area) => area['Name'] == areaName)['downVote'] -= 1;
        }
      } else {
        if (_userVotes[areaName] == "upvote") {
          _safeAreas.firstWhere((area) => area['Name'] == areaName)['upvote'] -=
              1;
          _safeAreas
              .firstWhere((area) => area['Name'] == areaName)['downVote'] += 1;
        } else if (_userVotes[areaName] == "downvote") {
          _safeAreas
              .firstWhere((area) => area['Name'] == areaName)['downVote'] -= 1;
          _safeAreas.firstWhere((area) => area['Name'] == areaName)['upvote'] +=
              1;
        } else {
          _safeAreas.firstWhere((area) => area['Name'] == areaName)[voteType] +=
              1;
        }
        _userVotes[areaName] = voteType;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Safe Areas', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _fetchSafeAreas,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Find Safe Areas',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black))
                  : _safeAreas.isEmpty
                      ? const Center(
                          child: Text('No safe areas found.',
                              style: TextStyle(color: Colors.black54)))
                      : ListView.builder(
                          itemCount: _safeAreas.length,
                          itemBuilder: (context, index) {
                            var area = _safeAreas[index];
                            return Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              child: ListTile(
                                title: Text(area['Name'] ?? 'Unknown Area',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Type: ${area['Type'] ?? 'Unknown'}\nLocation: (${area['latitude']}, ${area['longitude']})\nDistance: ${area['distance']} km',
                                  style: const TextStyle(color: Colors.black45),
                                ),
                                leading: const Icon(Icons.safety_divider_sharp,
                                    color: Colors.green),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.thumb_up,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _vote(area['Name'], "upvote"),
                                    ),
                                    Text(area['upvote'].toString()),
                                    IconButton(
                                      icon: Icon(Icons.thumb_down,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _vote(area['Name'], "downVote"),
                                    ),
                                    Text(area['downVote'].toString()),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

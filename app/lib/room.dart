import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NearbyRoomsPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const NearbyRoomsPage(
      {super.key, required this.latitude, required this.longitude});

  @override
  _NearbyRoomsPageState createState() => _NearbyRoomsPageState();
}

class _NearbyRoomsPageState extends State<NearbyRoomsPage> {
  Position? _currentPosition;
  List<dynamic> _nearbyRooms = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, String> _userVotes = {}; // Stores user votes for each room

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

  Future<void> _fetchNearbyRooms() async {
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
        // Uri.parse('/rooms/nearby?latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}'),
        Uri.parse(
            'http://127.0.0.1:8888/rooms/nearby?latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nearbyRooms = data['data'];
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch rooms. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching rooms: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _voteRoom(int index, bool isUpvote) async {
    var room = _nearbyRooms[index];

    // Determine current vote state
    bool alreadyUpvoted = room['userVote'] == 'upvote';
    bool alreadyDownvoted = room['userVote'] == 'downvote';

    // Set vote action
    String newVote = isUpvote
        ? (alreadyUpvoted ? 'remove' : 'upvote')
        : (alreadyDownvoted ? 'remove' : 'downvote');

    final response = await http.post(
      // Uri.parse('/rooms/vote'),
      Uri.parse('http://127.0.0.1:8888/rooms/vote'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'room_name': room['room_name'],
        'vote': newVote,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        // Update counts and userVote state
        if (newVote == 'upvote') {
          room['upvote'] += 1;
          if (alreadyDownvoted) {
            room['downVote'] -= 1;
          }
          room['userVote'] = 'upvote';
        } else if (newVote == 'downvote') {
          room['downVote'] += 1;
          if (alreadyUpvoted) {
            room['upvote'] -= 1;
          }
          room['userVote'] = 'downvote';
        } else if (newVote == 'remove') {
          if (alreadyUpvoted) {
            room['upvote'] -= 1;
          } else if (alreadyDownvoted) {
            room['downVote'] -= 1;
          }
          room['userVote'] = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            const Text('Nearby Rooms', style: TextStyle(color: Colors.black)),
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
              onPressed: _fetchNearbyRooms,
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
                  : const Text('Find Nearby Rooms',
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
                  : _nearbyRooms.isEmpty
                      ? const Center(
                          child: Text('No nearby rooms found.',
                              style: TextStyle(color: Colors.black54)))
                      : ListView.builder(
                          itemCount: _nearbyRooms.length,
                          itemBuilder: (context, index) {
                            var room = _nearbyRooms[index];
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
                                title: Text(room['room_name'] ?? 'Unknown Room',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Type: ${room['friendly_type'] ?? 'Unknown'}\nDistance: (${room['distance']}km)\nUpvotes: ${room['upvote']} | Downvotes: ${room['downVote']}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                leading: const Icon(Icons.meeting_room,
                                    color: Colors.green),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.thumb_up_outlined,
                                          color: Colors.green),
                                      onPressed: () => _voteRoom(index, true),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.thumb_down_outlined,
                                          color: Colors.red),
                                      onPressed: () => _voteRoom(index, false),
                                    ),
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

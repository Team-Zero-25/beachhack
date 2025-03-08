

import 'package:flutter/material.dart';
import 'package:saferoute/home.dart';

class SnackBars {
  static showSnackBarInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.blue[800]), // Icon matching the Tailwind style
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.blue[800]), // Text color
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[50], // Background color
        behavior: SnackBarBehavior.floating, // Optional: Makes it float above the content
        margin: const EdgeInsets.all(16), // Adds margin for floating behavior
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Tailwind-style rounded corners
        ),
        duration: const Duration(seconds: 3), // Visibility duration
      ),
    );
  }
}

class SlideToCancelButton extends StatelessWidget {
  const SlideToCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              'Slide to Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Dismissible(
            key: Key('slide-to-cancel'),
            direction:
            DismissDirection.horizontal, // Horizontal swipe direction
            onDismissed: (direction) {
              // Trigger cancel action when the button is dismissed (swiped)
              Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
              // Perform cancellation logic here
            },
            child: Stack(
              children: [
                // The sliding button (round) that moves
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sos,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // The fixed text that doesn't move

              ],
            ),
          ),
        ],
      ),
    );
  }
}

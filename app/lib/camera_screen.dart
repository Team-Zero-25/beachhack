import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera permission is required to use this feature.'),
        ),
      );
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _controller = CameraController(camera, ResolutionPreset.medium);
    await _controller?.initialize();

    if (!mounted) return;

    setState(() {});
  }

  void _startStreaming() {
    if (_controller != null && !_isStreaming) {
      _controller?.startImageStream((CameraImage image) async {
        // Convert the image to JPEG format
        final jpegBytes = await _convertYUV420toJPEG(image);

        // Send the frame to the Flask server
        await _sendFrameToServer(jpegBytes);
      });

      setState(() {
        _isStreaming = true;
      });
    }
  }

  void _stopStreaming() {
    if (_controller != null && _isStreaming) {
      _controller?.stopImageStream();

      setState(() {
        _isStreaming = false;
      });
    }
  }

  Future<List<int>> _convertYUV420toJPEG(CameraImage image) async {
    // Convert YUV420 image to JPEG format
    // You can use the `image` package or any other method to convert the image
    // For simplicity, this example assumes you have a method to convert the image
    // Replace this with your actual implementation
    return <int>[];
  }

  Future<void> _sendFrameToServer(List<int> jpegBytes) async {
    final response = await http.post(
      // Uri.parse('http://127.0.0.1:5000/video_feed'),
      Uri.parse('http://<YOUR_SERVER_IP>/video_feed'),
      headers: {'Content-Type': 'application/octet-stream'},
      body: jpegBytes,
    );

    if (response.statusCode != 200) {
      print('Failed to send frame to server');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Camera Stream')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isStreaming ? _stopStreaming : _startStreaming,
                child:
                    Text(_isStreaming ? 'Stop Streaming' : 'Start Streaming'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

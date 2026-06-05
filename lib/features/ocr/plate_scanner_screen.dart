import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ocr_service.dart';

class PlateScannerScreen extends StatefulWidget {
  const PlateScannerScreen({super.key});

  @override
  State<PlateScannerScreen> createState() => _PlateScannerScreenState();
}

class _PlateScannerScreenState extends State<PlateScannerScreen> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isInitializing = true;
  final OCRService _ocrService = OCRService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile image = await _controller!.takePicture();
      final String? result = await _ocrService.scanImage(image);

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      debugPrint("Error scanning: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تصوير لوحة السيارة'), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Center(
            child: Container(
              width: 300,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePictureAndScan,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

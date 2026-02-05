import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

/// Camera screen for capturing receipt images
/// 
/// Features:
/// - Camera preview with real-time display
/// - Back button (always visible, top-left)
/// - Photo trigger button (bottom center)
/// - After photo: Check button (top-right) and Reload button (replaces trigger)
/// - Shows captured image preview after taking photo
/// 
/// Navigation:
/// - Back button: Returns to register shopping list screen (discards photo)
/// - Reload button: Allows retaking the photo
/// - Check button: Shows progress dialog, then returns (photo discarded for now)
class ReceiptCameraScreen extends StatefulWidget {
  const ReceiptCameraScreen({super.key});

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize the camera
  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
          _isLoading = false;
        });
        return;
      }

      // Use the back camera by default
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Initialize camera controller
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Handle back button press
  void _handleBack() {
    Navigator.pop(context);
  }

  /// Take a picture
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking picture: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Retake the picture
  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  /// Handle check button - show progress dialog and return
  Future<void> _handleConfirm() async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Extracting prices and quantities...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Close the dialog
      Navigator.pop(context);
      // Return to register screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _handleBack,
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Camera preview or captured image
                      _buildCameraView(),

                      // Back button (always visible, top-left)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          onPressed: _handleBack,
                        ),
                      ),

                      // Check button (top-right, only visible after taking photo)
                      if (_capturedImage != null)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            onPressed: _handleConfirm,
                          ),
                        ),

                      // Bottom buttons
                      Positioned(
                        bottom: 32,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _capturedImage == null
                              ? _buildTriggerButton(colorScheme)
                              : _buildRetakeButton(colorScheme),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  /// Build camera preview or captured image
  Widget _buildCameraView() {
    if (_capturedImage != null) {
      // Show captured image
      return SizedBox.expand(
        child: Image.file(
          File(_capturedImage!.path),
          fit: BoxFit.contain,
        ),
      );
    }

    if (!_isCameraInitialized || _controller == null) {
      return const SizedBox.shrink();
    }

    // Show camera preview
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final cameraRatio = _controller!.value.aspectRatio;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.width * cameraRatio,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  /// Build photo trigger button
  Widget _buildTriggerButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: colorScheme.primary,
            width: 4,
          ),
        ),
      ),
    );
  }

  /// Build retake button
  Widget _buildRetakeButton(ColorScheme colorScheme) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.refresh,
          color: Colors.white,
          size: 32,
        ),
      ),
      onPressed: _retakePicture,
    );
  }
}

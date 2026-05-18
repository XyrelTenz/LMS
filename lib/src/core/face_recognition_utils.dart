import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/rust/api/face_api.dart' as face_api;
import 'package:librarymanagementsystem/src/rust/api/camera_api.dart'
    as camera_api;
import 'package:librarymanagementsystem/src/core/theme.dart';

class FaceScannerDialog extends StatefulWidget {
  final bool isRegistration;
  final String? userId;

  const FaceScannerDialog({
    super.key,
    required this.isRegistration,
    this.userId,
  });

  @override
  State<FaceScannerDialog> createState() => _FaceScannerDialogState();
}

class _FaceScannerDialogState extends State<FaceScannerDialog> {
  Uint8List? _currentFrame;
  bool _isProcessing = false;
  String _status = "Initializing native camera...";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initNativeCamera();
  }

  Future<void> _initNativeCamera() async {
    try {
      debugPrint("Initializing native camera...");
      await camera_api.initCamera();
      debugPrint("Native camera initialized successfully");
      if (!mounted) return;
      setState(
        () => _status = widget.isRegistration
            ? "Align your face to register"
            : "Scanning for face...",
      );

      _initFrameStreaming();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = "Camera error: $e");
    }
  }

  Future<void> _processFace() async {
    if (_currentFrame == null || _isProcessing) return;

    // Temporarily stop the timer to free up Rust threads/CPU for registration
    _timer?.cancel();

    setState(() {
      _isProcessing = true;
      _status = "Processing face...";
    });

    try {
      if (widget.isRegistration) {
        if (widget.userId == null) throw "User ID required for registration";
        await face_api.registerFace(
          userId: widget.userId!,
          imageBytes: _currentFrame!,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final userId = await face_api.verifyFace(imageBytes: _currentFrame!);
        if (!mounted) return;
        if (userId != null) {
          Navigator.pop(context, userId);
        } else {
          // Restart the timer if verification failed
          _initFrameStreaming();
          setState(() {
            _isProcessing = false;
            _status = "No match found. Try again.";
          });
        }
      }
    } catch (e) {
      // Restart the timer on error
      _initFrameStreaming();
      setState(() {
        _isProcessing = false;
        _status = "Error: $e";
      });
    }
  }

  void _initFrameStreaming() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) async {
      if (_isProcessing) return;
      try {
        final frameBytes = await camera_api.captureFrame();
        if (!mounted) return;
        setState(() {
          _currentFrame = frameBytes;
        });
      } catch (e) {
        debugPrint("Frame capture error: $e");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    camera_api.stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 400,
              width: 400,
              color: Colors.black,
              child: _currentFrame != null
                  ? Image.memory(_currentFrame!, fit: BoxFit.cover)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isProcessing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _processFace,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text(
                          widget.isRegistration ? "REGISTER FACE" : "SCAN FACE",
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

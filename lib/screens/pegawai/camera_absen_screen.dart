import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'dart:io';

class CameraAbsenScreen extends StatefulWidget {
  const CameraAbsenScreen({Key? key}) : super(key: key);

  @override
  State<CameraAbsenScreen> createState() => _CameraAbsenScreenState();
}

class _CameraAbsenScreenState extends State<CameraAbsenScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        Get.snackbar('Error', 'Kamera tidak ditemukan di perangkat ini');
        Get.back();
        return;
      }

      // Cari kamera depan
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Jika tidak ada kamera depan, pakai kamera pertama (biasanya belakang)
      frontCamera ??= _cameras!.first;

      _controller = CameraController(
        frontCamera,
        // ResolutionPreset.medium cukup ringan untuk hp low-end tapi gambarnya jelas
        ResolutionPreset.medium, 
        enableAudio: false,
        imageFormatGroup: Platform.isIOS 
            ? ImageFormatGroup.bgra8888 
            : ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal menginisialisasi kamera: $e');
      Get.back();
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile picture = await _controller!.takePicture();
      Get.back(result: picture.path);
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil foto: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Tampilan kamera fullscreen (dengan sedikit crop agar memenuhi layar)
          SizedBox(
            width: size.width,
            height: size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 100, // Ratio akan dihitung dari aspect ratio controller
                // Kalkulasi dimensi berdasarkan aspect ratio agar tidak gepeng
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          // Kamera sebenarnya:
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // Tombol Kembali
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
          ),

          // Tombol Shutter
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isTakingPicture ? Colors.grey : Colors.transparent,
                  ),
                  child: Center(
                    child: Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isTakingPicture ? Colors.grey[400] : Colors.white,
                      ),
                      child: _isTakingPicture
                          ? const CircularProgressIndicator(color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


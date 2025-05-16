import 'package:classifier_project2/utils/my_utils.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class CameraUploadScreen extends StatefulWidget {
  const CameraUploadScreen({super.key});

  @override
  _CameraUploadScreenState createState() => _CameraUploadScreenState();
}

class _CameraUploadScreenState extends State<CameraUploadScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;


  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _controller = CameraController(
          backCamera,
          ResolutionPreset.high,
        );

        _initializeControllerFuture = _controller.initialize();
        setState(() {});
      } else {
        showSafeSnackBar(context,'No premission for using camera!', Colors.red);
      }
    } catch (e) {
      showSafeSnackBar(context,'Error initializing camera: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromDevice() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      final result = await Navigator.of(this.context).push<String>(
        MaterialPageRoute(
          builder: (BuildContext context) => DisplayPictureScreen(
            imagePath: pickedFile.path,
            onImageAccepted: (imagePath) {
              if (mounted) {
                Navigator.of(context).pop(imagePath);
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _initializeControllerFuture == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRect(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller.value.previewSize?.height ?? 0,
                                  height: _controller.value.previewSize?.width ?? 0,
                                  child: CameraPreview(_controller),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;
                    final image = await _controller.takePicture();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DisplayPictureScreen(
                          imagePath: image.path,
                          onImageAccepted: (imagePath) {
                            if (mounted) {
                              Navigator.of(context).pop(imagePath);
                            }
                          },
                        ),
                      ),
                    );
                  } catch (e) {
                    showSafeSnackBar(context,'Error: $e', Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 54.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5.0,
                  splashFactory: InkRipple.splashFactory,
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.deepOrange;
                      }
                      return null;
                    },
                  ),
                ),
                child: const Text('Capture Photo'),
              ),
              ElevatedButton(
                onPressed: _pickImageFromDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5.0,
                  splashFactory: InkRipple.splashFactory,
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.deepOrange;
                      }
                      return null;
                    },
                  ),
                ),
                child: const Text('Upload from Device'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final Function(String) onImageAccepted;

  const DisplayPictureScreen({super.key, required this.imagePath, required this.onImageAccepted});

  Future<void> _uploadImageToBackend(BuildContext context, String imagePath) async {
    final uri = Uri.parse('$baseUrl/media/upload');
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      showSafeSnackBar(context, 'Error: JWT token is null. Please log in again.', Colors.red);
      return;
    }

    try {
      // Load the image asynchronously
      final Uint8List imageBytes = await File(imagePath).readAsBytes();
      final img.Image? originalImage = await img.decodeImage(Uint8List.fromList(imageBytes));
      if (originalImage == null) {
        showSafeSnackBar(context, 'Error: Unable to decode image.', Colors.red);
        return;
      }

      // Calculate the visible region based on the aspect ratio (1:1 for square)
      final double aspectRatio = 1.0; // Square aspect ratio
      int cropWidth, cropHeight, offsetX, offsetY;

      if (originalImage.width > originalImage.height) {
        cropHeight = originalImage.height;
        cropWidth = (cropHeight * aspectRatio).toInt();
        offsetX = (originalImage.width - cropWidth) ~/ 2;
        offsetY = 0;
      } else {
        cropWidth = originalImage.width;
        cropHeight = (cropWidth / aspectRatio).toInt();
        offsetX = 0;
        offsetY = (originalImage.height - cropHeight) ~/ 2;
      }

      // Crop the image to match the visible region
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: offsetX,
        y: offsetY,
        width: cropWidth,
        height: cropHeight,
      );

      // Encode the cropped image asynchronously
      final Uint8List croppedImageBytes = await img.encodeJpg(croppedImage);

      // Save the cropped image to a temporary file
      final croppedImagePath = '${imagePath}_cropped.jpg';
      await File(croppedImagePath).writeAsBytes(croppedImageBytes);

      final request = http.MultipartRequest('POST', uri);

      // Use the cropped image path
      request.files.add(await http.MultipartFile.fromPath('file', croppedImagePath));
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      final response = await request.send();
      print("Response sent!!!!!!!!!!!!!!!!!!!!! $response");
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseJson = json.decode(responseBody);
        print(responseBody);
        // Extract the imageUrl from the response
        final uploadedImageUrl = responseJson['updatedMedia']['imageUrl'];
        onImageAccepted(uploadedImageUrl); // Pass the uploaded image URL back
        showSafeSnackBar(context, 'Image uploaded successfully!', Colors.green);
        print(uploadedImageUrl);
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(imagePath);
        }
      } else {
        final responseBody = await response.stream.bytesToString();
        showSafeSnackBar(context, 'Failed to upload image: ${response.statusCode}', Colors.red);
        print('Response body: $responseBody');
      }
    } catch (e) {
      showSafeSnackBar(context, 'Error uploading image: $e', Colors.red);
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Picture'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Image.file(
                      File(imagePath),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5.0,
                  splashFactory: InkRipple.splashFactory,
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.deepOrange;
                      }
                      return null;
                    },
                  ),
                ),
                child: const Text('Retake'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _uploadImageToBackend(context, imagePath);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5.0,
                  splashFactory: InkRipple.splashFactory,
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.deepOrange;
                      }
                      return null;
                    },
                  ),
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

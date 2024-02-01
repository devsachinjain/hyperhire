import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'image_edit_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectImageFromGallery() async {
    try {
      final XFile? image =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final imagePath = image.path;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageEditScreen(imagePath: imagePath),
          ),
        );
      }
    } catch (e) {
      print('Error selecting image from gallery: $e');
    }
  }

  void _toggleCamera() {
    setState(() {
      final lensDirection = _controller.description.lensDirection;
      if (lensDirection == CameraLensDirection.front) {
        _controller =
            CameraController(widget.cameras[0], ResolutionPreset.medium);
      } else {
        _controller =
            CameraController(widget.cameras[1], ResolutionPreset.medium);
      }
      _initializeControllerFuture = _controller.initialize();
    });
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final XFile picture = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);

      final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
      final List<Face> faces = await faceDetector.processImage(inputImage);

      final int numberOfFaces = faces.length;


        // Save the image to the gallery
        final result = await ImageGallerySaver.saveFile(picture.path);
        print('Image saved to gallery: $result');

        // Navigate to ImageEditScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageEditScreen(
              imagePath: picture.path,
              numberOfFaces: numberOfFaces,
            ),
          ),
        );
      }
     catch (e) {
      print('Error taking picture: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.cancel_outlined,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          )
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Column(
                children: [
                  Container(
                      height: height / 1.6,
                      width: width,
                      child: CameraPreview(_controller)),
                  const SizedBox(
                    height: 30,
                  ),
                  InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      _takePicture();

                    },
                    child: const Icon(
                      Icons.circle,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: _selectImageFromGallery,
                          child: const Icon(
                            Icons.file_copy,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: _toggleCamera,
                          child: const Icon(
                            Icons.crop_rotate_outlined,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            } else {
              return const Center(
                  child: CircularProgressIndicator(
                color: Colors.black,
              ));
            }
          },
        ),
      ),
    );
  }
}

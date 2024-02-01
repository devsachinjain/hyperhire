import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class ImageEditScreen extends StatefulWidget {
  final String imagePath;
  final int? numberOfFaces;

  const ImageEditScreen({Key? key, required this.imagePath, this.numberOfFaces})
      : super(key: key);

  @override
  _ImageEditScreenState createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends State<ImageEditScreen> {
  bool isEyeAreaVisible = false;
  bool isMouthAreaVisible = false;

  Offset eyePosition = const Offset(0, 0);
  Offset mouthPosition = const Offset(0, 0);

  final GlobalKey globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.numberOfFaces! > 2) {
      Fluttertoast.showToast(
        msg: "More than 2 faces detected in the image!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 4,
        backgroundColor: Colors.grey[800],
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
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
      body: Column(
        children: [
          RepaintBoundary(
            key: globalKey,
            child: Stack(
              children: [
                SizedBox(
                  height: height / 1.8,
                  width: width,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                if (isEyeAreaVisible)
                  draggableGreenShape(
                    size: 20,
                    height: 20,
                    width: 20,
                    isEye: true,
                    position: eyePosition,
                    onChanged: (newPosition) {
                      setState(() {
                        eyePosition = newPosition;
                      });
                    },
                  ),
                if (isMouthAreaVisible)
                  draggableGreenShape(
                    size: 20,
                    height: 30,
                    width: 30,
                    isEye: false,
                    position: mouthPosition,
                    onChanged: (newPosition) {
                      setState(() {
                        mouthPosition = newPosition;
                      });
                    },
                  )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
            ),
            child: Row(
              children: [
                InkWell(
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    )),
                const SizedBox(
                  width: 10,
                ),
                const Text(
                  'Go back',
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          (widget.numberOfFaces! > 2)
              ? Container()
              : Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 20),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            // isEyeAreaVisible = true;
                            isEyeAreaVisible = !isEyeAreaVisible;
                          });
                        },
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color:
                                isEyeAreaVisible ? Colors.white : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Eye',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      InkWell(
                        onTap: () {
                          setState(() {
                            isMouthAreaVisible = !isMouthAreaVisible;
                          });
                        },
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: isMouthAreaVisible
                                ? Colors.white
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Mouth',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          (widget.numberOfFaces! > 2)
              ? Container()
              : InkWell(
                  onTap: () async {
                    await saveImageToGallery();
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isMouthAreaVisible && isEyeAreaVisible == true ||
                              isMouthAreaVisible == true ||
                              isEyeAreaVisible == true
                          ? Colors.deepPurple[400]
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Save'),
                    ),
                  ),
                )
        ],
      ),
    );
  }

  Future<void> saveImageToGallery() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result =
          await ImageGallerySaver.saveImage(Uint8List.fromList(pngBytes));

      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image')),
        );
      }
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save image')),
      );
    }
  }

  Widget draggableGreenShape({
    required Offset position,
    required ValueChanged<Offset> onChanged,
    required double size,
    required double height,
    required double width,
    bool isEye = false,
  }) {
    return Positioned(
        left: position.dx - (size / 10),
        top: position.dy - (size / 4),
        child: GestureDetector(
          onPanUpdate: (details) {
            onChanged(Offset(
              // Pass the new position to the onChanged callback
              //*4 speedy drag
              position.dx + details.delta.dx * 4,
              position.dy + details.delta.dy * 4,
            ));
          },
          child: isEye
              ? Row(
                  children: [
                    Container(
                      height: 25,
                      width: 50,
                      decoration: BoxDecoration(
                        // shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.5),

                        borderRadius:
                            const BorderRadius.all(Radius.elliptical(100, 50)),
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    Container(
                      height: 25,
                      width: 50,
                      decoration: BoxDecoration(
                        //shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.5),
                        borderRadius:
                            const BorderRadius.all(Radius.elliptical(100, 50)),
                      ),
                    ),
                  ],
                )
              : Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    // shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.5),
                    borderRadius:
                        const BorderRadius.all(Radius.elliptical(100, 50)),
                  ),
                ),
        ));
  }
}

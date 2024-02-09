import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:text_ocr/result_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late CameraController _controller;
  bool isLoading = false;
  bool isLoading1 = false;
  @override
  void initState() {
    super.initState();
    intializeCam();
  }

  intializeCam() async {
    await getCam();
  }

  Future<void> getCam() async {
    setState(() {
      isLoading1 = true;
    });
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    setState(() {
      isLoading1 = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading1
        // !_controller.value.isInitialized
        ? const SizedBox()
        : Scaffold(
            appBar: AppBar(
              title: const Text('Text Detector'),
              centerTitle: true,
            ),
            body: Stack(
              children: [
                Transform.scale(
                  scale: _controller.value.aspectRatio /
                      MediaQuery.of(context).size.aspectRatio,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2.0),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  final textRecognizer = TextRecognizer();
                  XFile xFile = await _controller.takePicture();
                  File file = File(xFile.path);
                  final inputImage = InputImage.fromFile(file);
                  final recognizedText =
                      await textRecognizer.processImage(inputImage);
                  await navigator.push(
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          ResultScreen(text: recognizedText.text),
                    ),
                  );
                  debugPrint(
                      ' \x1B[37m ---------------- Picture saved to ${xFile.path}----- recognizedText ${recognizedText.text} ');
                } catch (e) {
                  debugPrint('Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('An error occurred when scanning text'),
                    ),
                  );
                }
              },
              child: const Text('Scan text'),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
  }

  Future<XFile?> _cropImage(XFile imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    final Image image = Image.memory(bytes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Crop to the region of interest
    const double cropWidth = 200;
    const double cropHeight = 200;
    final double left = (image.width! - cropWidth) / 2;
    final double top = (image.height! - cropHeight) / 2;
    final Rect cropRect = Rect.fromLTWH(left, top, cropWidth, cropHeight);

    // Draw the cropped region to the canvas
    canvas.drawImageRect(image as ui.Image, cropRect,
        const Rect.fromLTWH(0, 0, cropWidth, cropHeight), Paint());

    final picture = recorder.endRecording();
    final img = await picture.toImage(cropWidth.toInt(), cropHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Save the cropped image to a file
    final croppedFile = File('${imageFile.path}_cropped.png');
    await croppedFile.writeAsBytes(buffer);

    return XFile(croppedFile.path);
  }
}

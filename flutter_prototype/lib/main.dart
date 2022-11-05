import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

late String imagePath;
int currentPage = 0;
Widget page = Column();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prototype"),
      ),
      body: page,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cameras = await availableCameras();
          final firstCamera = cameras.first;
          try {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return TakePictureScreen(camera: firstCamera);
                },
              ),
            );
            debugPrint(imagePath);
            final InputImage inputImage = InputImage.fromFile(File(imagePath));
            final textRecognizer =
                TextRecognizer(script: TextRecognitionScript.latin);
            final RecognizedText recognizedText =
                await textRecognizer.processImage(inputImage);

            String result = "Unidentified or not supported medicine.";
            for (TextBlock block in recognizedText.blocks) {
              for (TextLine line in block.lines) {
                for (TextElement element in line.elements) {
                  // todo connect with database for checking
                  if (element.text.toLowerCase() == "panadol") {
                    debugPrint('panadol');
                    result = "Panadol";
                    debugPrint(result);
                    break;
                  }
                }
              }
            }
            textRecognizer.close();
            setState(() {
              page = SingleChildScrollView(
                child: Center(
                  child: Column(children: [
                    Image.file(File(imagePath), height: 300),
                    SingleChildScrollView(
                      //placeholder
                      //todo display more detials and retrieve actual data from server
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(10),
                            child: Text(result),
                          ),
                          result != "Unidentified or not supported medicine."
                              ? Container(
                                  margin: const EdgeInsets.all(10),
                                  child: const Text('''
Functions: Panadol is indicated for: Headache, Colds & Influenza, Backache, Period Pain, Pain of Osteoarthritis, Muscle Pain, Toothache, Rheumatic Pain.'''),
                                )
                              : Container(),
                          result != "Unidentified or not supported medicine."
                              ? Container(
                                  margin: const EdgeInsets.all(10),
                                  child: const Text(
                                      "Usage: For oral use only. Swallow Panadol tablets with water."),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            });
          } finally {}
          debugPrint('floating action button');
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and then get the location
            // where the image file is saved.
            final image = await _controller.takePicture();
            debugPrint(image.path);
            imagePath = image.path;
            Navigator.of(context).pop();
          } catch (e) {
            // If an error occurs, log the error to the console.
            debugPrint(e.toString());
          } finally {}
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

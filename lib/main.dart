// ignore_for_file: unused_field, avoid_print

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Translator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final CameraController _cameraController;
  final _controller = TextEditingController();
  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage _targetLanguage = TranslateLanguage.korean;
  late final OnDeviceTranslator _onDeviceTranslator = OnDeviceTranslator(
    sourceLanguage: _sourceLanguage,
    targetLanguage: _targetLanguage,
  );
  final _translationController = StreamController<String>();
  final bool _cameraIsBusy = false;
  bool _recognitionIsBusy = false;
  late final stt.SpeechToText _speechToText;

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final bool _canProcess = true;
  final bool _isBusy = false;
  String? _text;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _translationController.close();
    _onDeviceTranslator.close();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSpeechToText();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future<void> captureAndRecognizeText() async {
    if (_recognitionIsBusy) return;
    _recognitionIsBusy = true;

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _recognizeText(InputImage.fromFilePath(image.path));
    }

    _recognitionIsBusy = false;
  }

  Future<void> _recognizeText(InputImage inputImage) async {
    _recognitionIsBusy = true;

    final recognizedText = await _textRecognizer.processImage(inputImage);
    _controller.text = recognizedText.text;

    _recognitionIsBusy = false;
  }

  Future<void> _initializeSpeechToText() async {
    _speechToText = stt.SpeechToText();
    await _speechToText.initialize();
  }

  void startListening() {
    _speechToText.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
    );
  }

  void stopListening() {
    _speechToText.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        toolbarHeight: 46,
        elevation: 0.0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: DropdownButtonFormField<TranslateLanguage>(
                      value: _sourceLanguage,
                      onChanged: (value) {
                        setState(() {
                          _sourceLanguage = value!;
                          print(_sourceLanguage);
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: TranslateLanguage.english,
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: TranslateLanguage.korean,
                          child: Text('Korean'),
                        ),
                        DropdownMenuItem(
                          value: TranslateLanguage.japanese,
                          child: Text('Japanese'),
                        ),
                        DropdownMenuItem(
                          value: TranslateLanguage.chinese,
                          child: Text('Chinese'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Input Language',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: DropdownButtonFormField<TranslateLanguage>(
                      value: _targetLanguage,
                      onChanged: (value) {
                        setState(() {
                          _targetLanguage = value!;
                          print(_targetLanguage);
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: TranslateLanguage.english,
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: TranslateLanguage.korean,
                          child: Text('Korean'),
                        ),
                        DropdownMenuItem(
                          value: TranslateLanguage.japanese,
                          child: Text('Japanese'),
                        ),
                        DropdownMenuItem(
                          value: TranslateLanguage.chinese,
                          child: Text('Chinese'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Target Language',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter what you want to translate',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) async {
                final translation =
                    await _onDeviceTranslator.translateText(text);
                _translationController.add(translation);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<String>(
              stream: _translationController.stream,
              builder: (context, snapshot) {
                return Center(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      snapshot.data ?? '',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          InkWell(
            onTap: () {
              captureAndRecognizeText();
            },
            child: Container(
              alignment: Alignment.center,
              height: 76,
              color: Colors.grey.shade300,
              child: const Icon(Icons.camera),
            ),
          ),
          InkWell(
            onTap: () {
              if (_speechToText.isListening) {
                stopListening();
              } else {
                startListening();
              }
            },
            child: Container(
              alignment: Alignment.center,
              height: 76,
              color: Colors.blueGrey,
              child: const Icon(Icons.mic),
            ),
          ),
        ],
      ),
    );
  }
}

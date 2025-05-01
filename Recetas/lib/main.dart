import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(home: FoodRecognizer()));
}

class FoodRecognizer extends StatefulWidget {
  const FoodRecognizer({super.key});

  @override
  State<FoodRecognizer> createState() => _FoodRecognizerState();
}

class _FoodRecognizerState extends State<FoodRecognizer> {
  File? _image;
  String? _prediction;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _prediction = null;
      });
      _sendToClarifai(File(picked.path));
    }
  }

  Future<void> _sendToClarifai(File imageFile) async {
    setState(() {
      _loading = true;
    });

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    const apiKey = '72e9b5298313461abec9d5396f28894f'; // your personal access token

    const modelId = 'food-item-recognition';
    const userId = 'clarifai';
    const appId = 'main';

    final url =
        'https://api.clarifai.com/v2/models/$modelId/outputs';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Key $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_app_id': {'user_id': userId, 'app_id': appId},
        'inputs': [
          {
            'data': {
              'image': {'base64': base64Image}
            }
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final concepts = decoded['outputs'][0]['data']['concepts'];
      final topPrediction = concepts[0];
      setState(() {
        _prediction = '${topPrediction['name']} (${(topPrediction['value'] * 100).toStringAsFixed(1)}%)';
      });
    } else {
      setState(() {
        _prediction = 'Error: ${response.statusCode}';
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Identifier')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Take a Picture'),
            ),
            const SizedBox(height: 20),
            if (_image != null) Image.file(_image!, height: 200),
            const SizedBox(height: 20),
            if (_loading)
              const CircularProgressIndicator()
            else if (_prediction != null)
              Text('Prediction: $_prediction', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

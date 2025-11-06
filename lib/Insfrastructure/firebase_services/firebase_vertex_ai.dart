import 'package:firebase_vertexai/firebase_vertexai.dart';

class FirebaseVertextAi {
  final model = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-2.0-flash',
  );

  Future<String> processPrompt(String userPrompt) async {
    final input = [Content.text(userPrompt)];

    final response = await model.generateContent(input);

    final generatedText = response.text;

    return generatedText!;
  }
}

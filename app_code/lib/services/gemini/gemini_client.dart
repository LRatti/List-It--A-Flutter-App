import 'package:google_generative_ai/google_generative_ai.dart';

/// Abstract interface for Gemini API communication.
/// Allows for easy testing with fake implementations.
abstract class GeminiClient {
  /// Generates text based on the provided prompt.
  /// 
  /// Returns the generated text, or empty string if no response.
  Future<String> generateText(String prompt);
}

/// Production implementation that calls the real Gemini API.
class RealGeminiClient implements GeminiClient {
  final String _apiKey;
  late final GenerativeModel _model;

  RealGeminiClient({required String apiKey}) : _apiKey = apiKey {
    _initModel();
  }

  void _initModel() {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    }
  }

  /// Sends a text [prompt] to the Gemini AI model and returns the generated response.
  /// 
  /// This method encapsulates the network call to the Generative AI service.
  /// Returns the model's text output, or an empty string if the generation fails.
  @override
  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      return '';
    }

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? '';
  }
}

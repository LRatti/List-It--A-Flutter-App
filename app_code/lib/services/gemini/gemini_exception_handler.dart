import 'package:app_code/models/recipe_response.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Handles Gemini API exceptions and converts them to user-friendly error messages.
class GeminiExceptionHandler {
  /// Converts a GenerativeAIException to a user-friendly RecipeData error.
  static RecipeData handleGenerativeAIException(GenerativeAIException e) {
    final msg = e.message;
    final lowerMsg = msg.toLowerCase();

    // Check for invalid/not found recipe
    if (lowerMsg.contains('not found') ||
        lowerMsg.contains('does not exist') ||
        lowerMsg.contains('unknown recipe')) {
      return RecipeData.error(
        'The recipe you searched for does not exist. Please check the spelling and try again.',
      );
    }

    // Check for quota/rate limit errors
    if (lowerMsg.contains('quota') ||
        lowerMsg.contains('rate limit') ||
        lowerMsg.contains('exceeded')) {
      return RecipeData.error(
        'Recipe service is temporarily unavailable. Please try again in a few moments.',
      );
    }

    // Check for connection errors
    if (lowerMsg.contains('socket') ||
        lowerMsg.contains('connection') ||
        lowerMsg.contains('timeout') ||
        lowerMsg.contains('network')) {
      return RecipeData.error(
        'Connection error. Please check your internet connection and try again.',
      );
    }

    // Default error
    return RecipeData.error(
      'Something went wrong while searching for the recipe. Please try again.',
    );
  }

  /// Converts a generic exception to a user-friendly RecipeData error.
  static RecipeData handleGenericException(Exception e) {
    final errorStr = e.toString().toLowerCase();
    // Check for connection/network errors
    if (errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('network')) {
      return RecipeData.error(
        'Connection error. Please check your internet connection and try again.',
      );
    }
    return RecipeData.error('Something went wrong. Please try again.');
  }
}

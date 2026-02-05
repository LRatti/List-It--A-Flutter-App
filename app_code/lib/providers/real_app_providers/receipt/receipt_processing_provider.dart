import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/repositories/real_app_repo/gemini_repository_real.dart';
import 'package:app_code/services/receipt/receipt_ocr_service.dart';

/// Provides the OCR service for receipt processing.
final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  return ReceiptOcrService();
});

/// Provides the Gemini repository for receipt extraction.
/// TODO: switch to a mock repository for testing purposes: 
/// MockgeminiRepository() / MockGeminiRepository()
final receiptGeminiRepositoryProvider = Provider<GeminiRepository>((ref) {
  return GeminiRepositoryReal();
});

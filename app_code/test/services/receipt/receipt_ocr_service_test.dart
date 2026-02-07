import 'dart:io';
import 'dart:typed_data';

import 'package:app_code/services/receipt/receipt_ocr_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mocktail/mocktail.dart';

/// Mock TextRecognizer for testing
class MockTextRecognizer extends Mock implements TextRecognizer {}

/// Mock RecognizedText for testing
class MockRecognizedText extends Mock implements RecognizedText {}

/// Mock for testing purposes - allows creating a testable ReceiptOcrService
class TestableReceiptOcrService extends ReceiptOcrService {
  final TextRecognizer mockRecognizer;

  TestableReceiptOcrService(this.mockRecognizer);

  @override
  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final recognizedText = await mockRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await mockRecognizer.close();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTextRecognizer mockRecognizer;
  late MockRecognizedText mockRecognizedText;
  late TestableReceiptOcrService service;
  late File testImageFile;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(InputImage.fromBytes(
      bytes: Uint8List(0),
      metadata: InputImageMetadata(
        size: const Size(100, 100),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: 100,
      ),
    ));
  });

  setUp(() {
    mockRecognizer = MockTextRecognizer();
    mockRecognizedText = MockRecognizedText();
    service = TestableReceiptOcrService(mockRecognizer);

    // Create a temporary test file
    testImageFile = File('test_receipt.jpg');
  });

  tearDown(() {
    // Clean up test file if it exists
    if (testImageFile.existsSync()) {
      testImageFile.deleteSync();
    }
  });

  group('ReceiptOcrService.extractText()', () {
    test('successfully extracts text from receipt image', () async {
      // Arrange
      const expectedText = '''
        SUPERMARKET XYZ
        123 Main Street
        ---
        Milk        \$3.50
        Bread       \$2.00
        Eggs        \$4.25
        ---
        Total:      \$9.75
      ''';

      // Create a dummy image file for testing
      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header

      when(() => mockRecognizedText.text).thenReturn(expectedText);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act
      final result = await service.extractText(testImageFile);

      // Assert
      expect(result, expectedText);
      verify(() => mockRecognizer.processImage(any())).called(1);
      verify(() => mockRecognizer.close()).called(1);
    });

    test('returns empty string when no text is recognized', () async {
      // Arrange
      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizedText.text).thenReturn('');
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act
      final result = await service.extractText(testImageFile);

      // Assert
      expect(result, '');
      verify(() => mockRecognizer.close()).called(1);
    });

    test('extracts text with special characters and symbols', () async {
      // Arrange
      const expectedText = '''
        Store #42 @ Mall
        Items: Café au lait €3.50
        Tax (21%): €0.74
        Total: €4.24
      ''';

      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizedText.text).thenReturn(expectedText);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act
      final result = await service.extractText(testImageFile);

      // Assert
      expect(result, expectedText);
      expect(result, contains('€'));
      expect(result, contains('%'));
      expect(result, contains('@'));
    });

    test('extracts multiline text correctly', () async {
      // Arrange
      const expectedText = '''Line 1
Line 2
Line 3''';

      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizedText.text).thenReturn(expectedText);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act
      final result = await service.extractText(testImageFile);

      // Assert
      expect(result.split('\n').length, 3);
      verify(() => mockRecognizer.processImage(any())).called(1);
    });

    test('closes recognizer even when processImage throws exception', () async {
      // Arrange
      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizer.processImage(any()))
          .thenThrow(Exception('ML Kit error'));
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => service.extractText(testImageFile),
        throwsException,
      );

      // Wait a bit to allow async cleanup
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify close was called despite the exception
      verify(() => mockRecognizer.close()).called(1);
    });

    test('handles OCR processing error', () async {
      // Arrange
      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizer.processImage(any()))
          .thenThrow(Exception('OCR processing failed'));
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => service.extractText(testImageFile),
        throwsException,
      );
    });

    test('handles corrupted image file', () async {
      // Arrange - create file with invalid image data
      testImageFile.writeAsBytesSync([0x00, 0x00, 0x00, 0x00]);

      when(() => mockRecognizer.processImage(any()))
          .thenThrow(Exception('Invalid image format'));
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => service.extractText(testImageFile),
        throwsException,
      );
    });

    test('extracts text with numbers and mixed content', () async {
      // Arrange
      const expectedText = '''
        Product A: 123
        Product B: 456.78
        Discount: -10.00
        Total: 569.78
      ''';

      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizedText.text).thenReturn(expectedText);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act
      final result = await service.extractText(testImageFile);

      // Assert
      expect(result, contains('123'));
      expect(result, contains('456.78'));
      expect(result, contains('-10.00'));
    });

    test('handles text with only whitespace', () async {
      // Arrange
      const expectedText = '   \n\n   \t  ';

      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizedText.text).thenReturn(expectedText);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act
      final result = await service.extractText(testImageFile);

      // Assert
      expect(result, expectedText);
      verify(() => mockRecognizer.close()).called(1);
    });

    test('extracts long receipt text', () async {
      // Arrange - simulate a long receipt
      final longText = List.generate(100, (i) => 'Item $i: \$${i + 1}.00').join('\n');

      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizedText.text).thenReturn(longText);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act
      final result = await service.extractText(testImageFile);

      // Assert
      expect(result.length, greaterThan(100));
      expect(result, contains('Item 0'));
      expect(result, contains('Item 99'));
    });

    test('handles ML Kit timeout error', () async {
      // Arrange
      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizer.processImage(any()))
          .thenThrow(Exception('Timeout waiting for ML Kit response'));
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => service.extractText(testImageFile),
        throwsException,
      );
    });

    test('handles memory error during processing', () async {
      // Arrange
      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizer.processImage(any()))
          .thenThrow(Exception('Out of memory'));
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => service.extractText(testImageFile),
        throwsException,
      );
    });

    test('extracts text with international characters', () async {
      // Arrange
      const expectedText = '''
        日本語
        中文
        한국어
        العربية
      ''';

      testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      when(() => mockRecognizedText.text).thenReturn(expectedText);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);
      when(() => mockRecognizer.close()).thenAnswer((_) async {});

      // Act
      final result = await service.extractText(testImageFile);

      // Assert
      expect(result, expectedText);
    });
  });
}

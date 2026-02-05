import 'dart:convert';

import 'package:app_code/models/receipt_match.dart';

/// Parses Gemini receipt extraction responses into ReceiptMatch items.
class ReceiptResponseParser {
  static List<ReceiptMatch> parse(String content) {
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    if (jsonMatch == null) {
      throw const FormatException('Receipt service returned an invalid response.');
    }

    final jsonString = jsonMatch.group(0)!;
    final decoded = jsonDecode(jsonString);

    final matches = <ReceiptMatch>[];
    final items = decoded is Map<String, dynamic>
        ? (decoded['matches'] ?? decoded['items'] ?? decoded['products'])
        : null;

    if (items is! List) {
      return matches;
    }

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final productId = _asString(item['product_id'] ?? item['productId'] ?? item['id']);
      final productName = _asString(item['product_name'] ?? item['productName'] ?? item['name']);
      final quantity = _parseInt(item['quantity']);
      final price = _parseDouble(item['price']);

      if (quantity == null || price == null) {
        continue;
      }

      matches.add(
        ReceiptMatch(
          productId: productId,
          productName: productName,
          quantity: quantity,
          price: price,
        ),
      );
    }

    return matches;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    final str = value.toString();
    final cleaned = RegExp(r'\d+').firstMatch(str)?.group(0);
    if (cleaned == null) return null;
    return int.tryParse(cleaned);
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    var str = value.toString().trim();
    if (str.isEmpty) return null;

    str = str.replaceAll(',', '.');
    str = str.replaceAll(RegExp(r'[^0-9\.]'), '');
    if (str.isEmpty) return null;

    return double.tryParse(str);
  }
}

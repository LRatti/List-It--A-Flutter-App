import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:app_code/utils/category_localizer.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';

const String _mockCategoriesJson = '''
{
  "categories": [
    {
      "name": "Uncategorized",
      "labels": {
        "en": "Uncategorized",
        "it": "Senza categoria"
      }
    },
    {
      "name": "Test Category",
      "labels": {
        "en": "Test EN",
        "it": "Test IT"
      }
    }
  ]
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'assets/data/default_categories.json') {
          final bytes = Uint8List.fromList(utf8.encode(_mockCategoriesJson));
          return ByteData.view(bytes.buffer);
        }
        return null;
      },
    );

    await CategoryLocalizer.preload();
  });

  Future<String> _localize(WidgetTester tester, String locale, String name) async {
    String? localized;

    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [
          Locale('en'),
          Locale('it'),
          Locale('fr'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            localized = CategoryLocalizer.localize(context, name);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return localized ?? '';
  }

  testWidgets('localizes known category for matching locale', (tester) async {
    final localized = await _localize(tester, 'it', 'Test Category');

    expect(localized, 'Test IT');
  });

  testWidgets('falls back to English when locale is missing', (tester) async {
    final localized = await _localize(tester, 'fr', 'Test Category');

    expect(localized, 'Test EN');
  });

  testWidgets('returns raw name for unknown category', (tester) async {
    final localized = await _localize(tester, 'it', 'Unknown Category');

    expect(localized, 'Unknown Category');
  });

  testWidgets('localizes uncategorized label', (tester) async {
    final localized = await _localize(
      tester,
      'it',
      UncategorizedCategoryUtils.name,
    );

    expect(localized, 'Senza categoria');
  });
}

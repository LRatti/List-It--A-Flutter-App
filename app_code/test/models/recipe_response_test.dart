import 'package:app_code/models/product.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeData', () {
    test('hasError derived from error value', () {
      final ok = RecipeData(
        products: [],
        quantities: [],
        productCategories: [],
        recipeName: 'Empty',
        error: 'noError',
      );
      final err = RecipeData.error('fail');

      expect(ok.hasError, false);
      expect(err.hasError, true);
    });

    test('toJson and fromJson roundtrip', () {
      final data = RecipeData(
        products: [Product(name: 'Tomato'), Product(name: 'Basil')],
        quantities: ['2', '5 leaves'],
        productCategories: ['Veg', 'Herb'],
        recipeName: 'Salad',
        error: 'noError',
      );

      final json = data.toJson();
      final restored = RecipeData.fromJson(json);

      expect(restored.products.map((p) => p.getName()).toList(), ['Tomato', 'Basil']);
      expect(restored.quantities, ['2', '5 leaves']);
      expect(restored.productCategories, ['Veg', 'Herb']);
      expect(restored.recipeName, 'Salad');
      expect(restored.error, 'noError');
      expect(restored.hasError, false);
    });

    test('toJsonString and fromJsonString roundtrip', () {
      final data = RecipeData(
        products: [Product(name: 'Pasta')],
        quantities: ['500g'],
        productCategories: ['Grains'],
        recipeName: 'Pasta',
        error: 'noError',
      );

      final jsonString = data.toJsonString();
      final restored = RecipeData.fromJsonString(jsonString);

      expect(restored.recipeName, 'Pasta');
      expect(restored.products.first.getName(), 'Pasta');
      expect(restored.quantities.first, '500g');
      expect(restored.productCategories.first, 'Grains');
      expect(restored.hasError, false);
    });

    test('empty factory produces defaults', () {
      final data = RecipeData.empty();

      expect(data.products, isEmpty);
      expect(data.quantities, isEmpty);
      expect(data.productCategories, isEmpty);
      expect(data.recipeName, '');
      expect(data.error, 'noError');
      expect(data.hasError, false);
    });
  });
}

import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'dart:math';

/// Test implementation of GeminiRepository for testing purposes
/// Returns mock recipe data without making actual API calls
class MockGeminiRepository implements GeminiRepository {
  final Random _random = Random();

  @override
  Future<RecipeData> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 5));

    final normalizedInput = recipeName.toLowerCase().trim();

    // Check if user is requesting an error
    if (normalizedInput == 'error') {
      return RecipeData.error('"$recipeName" not found. Try again.');
    }

    // Map of test recipes
    final testRecipes = [
      {
        'products': [
          Product(name: 'Flour'),
          Product(name: 'Cocoa powder'),
          Product(name: 'Sugar'),
          Product(name: 'Eggs'),
          Product(name: 'Butter'),
          Product(name: 'Milk'),
        ],
        'quantities': ['2 cups', '1 cup', '1.5 cups', '3', '100g', '1 cup'],
        'categories': ['Bakery', 'Bakery', 'Bakery', 'Dairy', 'Dairy', 'Dairy'],
        'name': 'Chocolate Cake',
      },
      {
        'products': [
          Product(name: 'Pasta'),
          Product(name: 'Bacon'),
          Product(name: 'Eggs'),
          Product(name: 'Parmesan cheese'),
          Product(name: 'Black pepper'),
        ],
        'quantities': ['400g', '200g', '4', '100g', 'to taste'],
        'categories': ['Bakery', 'Meat', 'Dairy', 'Dairy', 'Bakery'],
        'name': 'Pasta Carbonara',
      },
      {
        'products': [
          Product(name: 'Tomatoes'),
          Product(name: 'Onion'),
          Product(name: 'Garlic'),
          Product(name: 'Vegetable broth'),
          Product(name: 'Cream'),
          Product(name: 'Olive oil'),
        ],
        'quantities': ['1kg', '1', '3 cloves', '1 liter', '200ml', '2 tbsp'],
        'categories': [
          'Vegetables',
          'Vegetables',
          'Vegetables',
          'Bakery',
          'Dairy',
          'Bakery',
        ],
        'name': 'Tomato Soup',
      },
    ];

    // Return a random recipe from the list
    final randomRecipe = testRecipes[_random.nextInt(testRecipes.length)];

    return RecipeData(
      products: List.from(randomRecipe['products'] as List<Product>),
      quantities: List.from(randomRecipe['quantities'] as List<String>),
      productCategories: List.from(randomRecipe['categories'] as List<String>),
      recipeName: randomRecipe['name'] as String,
      error: 'noError',
    );
  }

  @override
  Future<String> categorizeProduct({
    required String productName,
    required List<Category> categories,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 5));

    final normalizedProduct = productName.toLowerCase().trim();

    // Simple mock categorization based on product name
    if (normalizedProduct.contains('milk') || normalizedProduct.contains('cheese') ||
        normalizedProduct.contains('yogurt') || normalizedProduct.contains('butter') ||
        normalizedProduct.contains('egg')) {
      return _findCategory(categories, 'Dairy');
    } else if (normalizedProduct.contains('apple') || normalizedProduct.contains('banana') ||
        normalizedProduct.contains('orange') || normalizedProduct.contains('grape')) {
      return _findCategory(categories, 'Fruits');
    } else if (normalizedProduct.contains('tomato') || normalizedProduct.contains('carrot') ||
        normalizedProduct.contains('lettuce') || normalizedProduct.contains('onion') ||
        normalizedProduct.contains('garlic')) {
      return _findCategory(categories, 'Vegetables');
    } else if (normalizedProduct.contains('beef') || normalizedProduct.contains('chicken') ||
        normalizedProduct.contains('pork') || normalizedProduct.contains('bacon') ||
        normalizedProduct.contains('meat')) {
      return _findCategory(categories, 'Meat');
    } else if (normalizedProduct.contains('bread') || normalizedProduct.contains('flour') ||
        normalizedProduct.contains('pasta') || normalizedProduct.contains('cake')) {
      return _findCategory(categories, 'Bakery');
    } else if (normalizedProduct.contains('water') || normalizedProduct.contains('juice') ||
        normalizedProduct.contains('soda') || normalizedProduct.contains('coffee') ||
        normalizedProduct.contains('tea')) {
      return _findCategory(categories, 'Beverages');
    }

    return _findCategory(categories, 'uncategorized');
  }

  @override
  Future<List<ReceiptMatch>> extractReceiptMatches({
    required String receiptText,
    required List<PurchasedProduct> purchasedProducts,
  }) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));
    return [];
  }

  String _findCategory(List<Category> categories, String targetName) {
    try {
      return categories
          .firstWhere((cat) => cat.getName().toLowerCase() == targetName.toLowerCase())
          .getName();
    } catch (e) {
      return 'uncategorized';
    }
  }
}

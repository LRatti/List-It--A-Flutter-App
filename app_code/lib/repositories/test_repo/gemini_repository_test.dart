import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';

/// Test implementation of GeminiRepository for testing purposes
/// Returns mock recipe data without making actual API calls
class GeminiRepositoryTest implements GeminiRepository {
  
  @override
  Future<RecipeData> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Map of test recipes
    final testRecipes = {
      'chocolate cake': {
        'products': [
          Product(name: 'Flour'),
          Product(name: 'Cocoa powder'),
          Product(name: 'Sugar'),
          Product(name: 'Eggs'),
          Product(name: 'Butter'),
          Product(name: 'Milk'),
        ],
        'quantities': ['2 cups', '1 cup', '1.5 cups', '3', '100g', '1 cup'],
        'categories': ['grains', 'pantry', 'pantry', 'dairy', 'dairy', 'dairy'],
        'name': 'Chocolate Cake',
      },
      'pasta carbonara': {
        'products': [
          Product(name: 'Pasta'),
          Product(name: 'Bacon'),
          Product(name: 'Eggs'),
          Product(name: 'Parmesan cheese'),
          Product(name: 'Black pepper'),
        ],
        'quantities': ['400g', '200g', '4', '100g', 'to taste'],
        'categories': ['grains', 'meat', 'dairy', 'dairy', 'pantry'],
        'name': 'Pasta Carbonara',
      },
      'tomato soup': {
        'products': [
          Product(name: 'Tomatoes'),
          Product(name: 'Onion'),
          Product(name: 'Garlic'),
          Product(name: 'Vegetable broth'),
          Product(name: 'Cream'),
          Product(name: 'Olive oil'),
        ],
        'quantities': ['1kg', '1', '3 cloves', '1 liter', '200ml', '2 tbsp'],
        'categories': ['vegetables', 'vegetables', 'vegetables', 'pantry', 'dairy', 'pantry'],
        'name': 'Tomato Soup',
      },
    };

    final normalizedInput = recipeName.toLowerCase().trim();
    
    // Check if recipe exists
    if (testRecipes.containsKey(normalizedInput)) {
      final recipe = testRecipes[normalizedInput]!;
      return RecipeData(
        products: List.from(recipe['products'] as List<Product>),
        quantities: List.from(recipe['quantities'] as List<String>),
        productCategories: List.from(recipe['categories'] as List<String>),
        recipeName: recipe['name'] as String,
        error: 'noError',
      );
    }

    // Check for partial matches (case-insensitive)
    for (final key in testRecipes.keys) {
      if (key.contains(normalizedInput) || normalizedInput.contains(key)) {
        final recipe = testRecipes[key]!;
        return RecipeData(
          products: List.from(recipe['products'] as List<Product>),
          quantities: List.from(recipe['quantities'] as List<String>),
          productCategories: List.from(recipe['categories'] as List<String>),
          recipeName: recipe['name'] as String,
          error: 'noError',
        );
      }
    }

    // Recipe not found
    return RecipeData.error('Recipe "$recipeName" not found in our database.');
  }
}

/// Builds prompts for Gemini API requests.
class GeminiPromptBuilder {
  /// Builds a recipe query prompt.
  static String buildRecipePrompt(String recipeName, String categories) {
    return '''
You are a recipe expert. The user wants to know the ingredients needed to make the recipe: "$recipeName".

Your task:
1. If the recipe exists, provide a list of all necessary products/ingredients with their quantities.
2. Classify each product into one of these categories: $categories
3. Return the corrected recipe name (in case the user misspelled it).
4. If the recipe doesn't exist, return an error message.

IMPORTANT GUIDELINES FOR PRODUCT NAMES:
- Use specific product names as they would be purchased. For example:
  - For carbonara: use "eggs" (not "whole egg")
  - For egg white only: use "egg white" (not "eggs")
  - For ground beef: use "ground beef" (not "beef")
  - For olive oil: use "olive oil" (not "oil")
- Always write the product name in its simplest shopping form.

IMPORTANT: You MUST return a valid JSON response with this exact structure:
{
  "products": [
    {
      "name": "ingredient name",
      "category": "category name",
      "quantity": "quantity with unit (e.g., 2 cups, 200g)"
    },
    ...
  ],
  "recipe_name": "actual recipe name",
  "error": "noError" or "Error description if recipe not found"
}

Ensure the JSON is valid and can be parsed. Return ONLY the JSON object, no additional text.
''';
  }

  /// Builds a product categorization prompt.
  static String buildCategorizationPrompt(
      String productName, String categoryNames) {
    return '''
You are a product categorization expert.

The user wants to categorize the product: "$productName"

Available categories: $categoryNames

Your task:
1. Choose the most appropriate category for this product from the available categories.
2. If the product doesn't fit any category well, choose "uncategorized".
3. Return ONLY the category name, nothing else.

IMPORTANT: Return ONLY the category name as plain text, no JSON, no quotes, no additional text.
''';
  }

  /// Builds a receipt extraction prompt for prices and quantities.
  static String buildReceiptExtractionPrompt({
    required String receiptText,
    required String purchasedProducts,
  }) {
    return '''
You are an expert receipt parser.

Given the receipt text and the list of purchased products (with their IDs and names),
return a JSON object that maps ONLY the products you can confidently match.

Rules:
1. Return JSON ONLY. No markdown, no explanations, no extra text.
2. Include ONLY products from the provided list.
3. For each matched product, return its product_id, quantity, and price.
4. Quantity must be an integer. If quantity is not explicit, infer 1.
5. Price must be a number using a dot as decimal separator.
6. Omit any product if you cannot confidently match it or if price is missing.

Return JSON with this exact structure:
{
  "matches": [
    {
      "product_id": "<id>",
      "product_name": "<name>",
      "quantity": 1,
      "price": 2.99
    }
  ]
}

Purchased products list:
$purchasedProducts

Receipt text:
$receiptText
''';
  }
}

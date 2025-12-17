import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';

void main() async{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MobileHomeListPage(),
    );
  }
}

class MobileHomeListPage extends StatefulWidget {
  const MobileHomeListPage({super.key});

  @override
  State<MobileHomeListPage> createState() => _MobileHomeListPageState();
}

class _MobileHomeListPageState extends State<MobileHomeListPage> {
  List<ShoppingList> _shoppingLists = [];

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  /// Loads all shopping lists from database.
  Future<void> _loadShoppingLists() async {
    final shoppingLists = await ManageShoppingList.getAllShoppingLists();
    setState(() {
      _shoppingLists = shoppingLists;
    });
  }

  /// Creates a new empty shopping list
  Future<void> _addShoppingList(String title) async {
    if (title.trim().isEmpty) return;
    //TODO: delete testing mock data
    
    final List<PurchasedProduct> productsList = [
      PurchasedProduct(
        listId: title,
        product: Product(
          id: 'p1',
          name: 'Potatoes',
        ),
        category: Category(
          id: 'c1',
          name: 'Vegetables',
        ),
        price: 1.50,
        quantity: 2,
      ),
      PurchasedProduct(
        listId: title,
        product: Product(
          id: 'p2',
          name: 'Tomatoes',
        ),
        category: Category(
          id: 'c1',
          name: 'Vegetables',
        ),
        price: 2.30,
        quantity: 1,
      ),
      PurchasedProduct(
        listId: title,
        product: Product(
          id: 'p3',
          name: 'Milk',
        ),
        category: Category(
          id: 'c2',
          name: 'Dairy',
        ),
        price: 1.20,
        quantity: 1,
      ),
      PurchasedProduct(
        listId: title,
        product: Product(
          id: 'p4',
          name: 'Bread',
        ),
        category: Category(
          id: 'c3',
          name: 'Bakery',
        ),
        price: 0.90,
        quantity: 1,
      ),
    ];


    final shoppingList = ShoppingList(
      id: title,
      name: title,
      createdAt: DateTime.now(),
      products: productsList
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    // Reload to keep DB and UI in sync
    await _loadShoppingLists();
  }

  /// Deletes a shopping list
  Future<void> _deleteShoppingList(int index) async {
    final shoppingList = _shoppingLists[index];

    await ManageShoppingList.deleteShoppingList(shoppingList);

    setState(() {
      _shoppingLists.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("List '${shoppingList.getName()}' deleted."),
      ),
    );
  }

  /// Edits shopping list title
  Future<void> _editShoppingListTitle(int index) async {
    final shoppingList = _shoppingLists[index];
    final controller = TextEditingController(text: shoppingList.getName());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit list title"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "List title"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                shoppingList.setName(controller.text.trim());
                await ManageShoppingList.updateShoppingList(shoppingList);
                await _loadShoppingLists();
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Opens list detail page and reloads data when returning
  Future<void> _openShoppingListDetail(ShoppingList shoppingList) async {
    // TODO: Replace with real detail page
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(shoppingList.getName()),
        content: const Text("Shopping list detail here"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );

    // Reload lists to refresh preview after modifications
    await _loadShoppingLists();
  }

  /// Shows dialog to create a new list
  void _showAddShoppingListDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add new list"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "List name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _addShoppingList(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddShoppingListDialog,
        child: const Icon(Icons.add),
      ),
      body: _shoppingLists.isEmpty
          ? const Center(
              child: Text(
                "No lists yet.\nTap + to create one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: _shoppingLists.length,
              itemBuilder: (context, index) {
                final shoppingList = _shoppingLists[index];
                return ShoppingListCard(
                  shoppingList: shoppingList,
                  onTap: () => _openShoppingListDetail(shoppingList),
                  onEdit: () => _editShoppingListTitle(index),
                  onDelete: () => _deleteShoppingList(index),
                );
              },
            ),
    );
  }
}

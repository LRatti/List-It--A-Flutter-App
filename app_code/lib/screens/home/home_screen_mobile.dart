import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';

void main() async {
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

  // Index of currently selected bottom navigation item
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  /// Loads all shopping lists from database
  Future<void> _loadShoppingLists() async {
    final shoppingLists = await ManageShoppingList.getAllShoppingLists();
    setState(() {
      _shoppingLists = shoppingLists;
    });
  }

  /// Creates a new shopping list with mock products
  Future<void> _addShoppingList(String title) async {
    if (title.trim().isEmpty) return;

    final List<PurchasedProduct> productsList = [
      PurchasedProduct(
        listId: title,
        product: Product(id: 'p1', name: 'Potatoes'),
        category: Category(id: 'c1', name: 'Vegetables'),
        price: 1.50,
        quantity: 2,
      ),
      PurchasedProduct(
        listId: title,
        product: Product(id: 'p2', name: 'Tomatoes'),
        category: Category(id: 'c1', name: 'Vegetables'),
        price: 2.30,
        quantity: 1,
      ),
      PurchasedProduct(
        listId: title,
        product: Product(id: 'p3', name: 'Milk'),
        category: Category(id: 'c2', name: 'Dairy'),
        price: 1.20,
        quantity: 1,
      ),
      PurchasedProduct(
        listId: title,
        product: Product(id: 'p4', name: 'Bread'),
        category: Category(id: 'c3', name: 'Bakery'),
        price: 0.90,
        quantity: 1,
      ),
    ];

    final shoppingList = ShoppingList(
      id: title,
      name: title,
      createdAt: DateTime.now(),
      products: productsList,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

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
      SnackBar(content: Text("List '${shoppingList.getName()}' deleted.")),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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

  /// Opens shopping list detail (mock for now)
  Future<void> _openShoppingListDetail(ShoppingList shoppingList) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(shoppingList.getName()),
        content: const Text("Shopping list detail here"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );

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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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

  /// Handles bottom navigation item tap
  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Returns the content widget for the selected tab
  Widget _getSelectedTabContent() {
    switch (_selectedIndex) {
      case 0: // Lists
        return _shoppingLists.isEmpty
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
              );
      case 1:
        return const Center(child: Text("History - mock screen"));
      case 2:
        return const Center(child: Text("Supermarkets - mock screen"));
      case 3:
        return const Center(child: Text("Statistics - mock screen"));
      default:
        return const Center(child: Text("Unknown tab"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Shopping App"),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)), // Settings button
          IconButton(onPressed: () {}, icon: const Icon(Icons.person)),   // Profile button
        ],
      ),
      body: Column(
        children: [
          // Top space for nearest supermarket link
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: const EdgeInsets.all(12),
            child: const Text(
              "Nearest supermarket: internet not available",
              style: TextStyle(fontSize: 16),
            ),
          ),
          // Expanded area for selected tab content
          Expanded(child: _getSelectedTabContent()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.white, // Background color of the bar
        selectedItemColor: Colors.blue, // Color of selected item
        unselectedItemColor: Colors.grey, // Color of unselected items
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // Ensures all labels are shown
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Lists"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Supermarkets"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistics"),
        ],
      ),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddShoppingListDialog,
              child: const Icon(Icons.add),
            )
          : null, // Only show FAB on Lists tab
    );
  }
}

import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_list.dart';
import 'package:flutter/material.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';

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

  Future<void> _loadShoppingLists() async {
    final shoppingLists = await ManageShoppingList.getAllShoppingLists();
    setState(() => _shoppingLists = shoppingLists);
  }

  Future<void> _addShoppingList(String title) async {
    if (title.isEmpty) return;
    ShoppingList shoppingList = ShoppingList(
      name: title,
      createdAt: DateTime.now(),
    );

    await ManageShoppingList.addShoppingList(shoppingList);
    
    setState(() => _shoppingLists.insert(0, shoppingList));
  }

  Future<void> _deleteShoppingList(int index) async {
    final shoppingList = _shoppingLists[index];
    if (shoppingList.id != null) await ManageShoppingList.deleteShoppingList(shoppingList);
    setState(() => _shoppingLists.removeAt(index));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Note '${shoppingList.getName()}' deleted.")));
  }

  Future<void> _editShoppingListTitle(int index) async {
    final shoppingList = _shoppingLists[index];
    TextEditingController controller = TextEditingController(text: shoppingList.getName());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit note title"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Note title"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                shoppingList.setName(controller.text);
                await ManageShoppingList.updateShoppingList(shoppingList);
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _openShoppingListDetail(ShoppingList shoppingList) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(shoppingList.getName()),
      content: const Text("Details here..."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        )
      ],
    ),
  );
}

  void _showAddShoppingListDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Note"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter note title"),
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
                "No Lists added yet. Tap '+' to add one!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
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
import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:app_code/controllers/lists_controller.dart';

/// Lists page showing all shopping lists with add/edit/delete functionality
class ListsScreenMobile extends StatefulWidget {
  /// Controller that manages shopping lists
  final ListsController controller;

  const ListsScreenMobile({super.key, required this.controller});

  @override
  State<ListsScreenMobile> createState() => _ListsScreenMobileState();
}

class _ListsScreenMobileState extends State<ListsScreenMobile> {
  List<ShoppingList> _shoppingLists = [];

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  /// Load all shopping lists via controller
  Future<void> _loadShoppingLists() async {
    final lists = await widget.controller.loadLists();
    setState(() {
      _shoppingLists = lists;
    });
  }

  /// Show dialog to add a new shopping list
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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newList = ShoppingList(
                  name: name,
                  createdAt: DateTime.now(),
                );
                await widget.controller.addList(newList);
                await _loadShoppingLists();
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit a shopping list
  void _showEditShoppingListDialog(ShoppingList list) {
    final controller = TextEditingController(text: list.getName());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit list"),
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
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                list.setName(newName);
                await widget.controller.updateList(list);
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

  /// Delete a shopping list
  Future<void> _deleteShoppingList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete list"),
        content: Text("Are you sure you want to delete '${list.getName()}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.deleteList(list);
      await _loadShoppingLists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _shoppingLists.isEmpty
          ? const Center(
              child: Text(
                "No lists yet.\nTap + to create one.",
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
                  onTap: () {}, // TODO: implement detail screen
                  onEdit: () => _showEditShoppingListDialog(shoppingList),
                  onDelete: () => _deleteShoppingList(shoppingList),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddShoppingListDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

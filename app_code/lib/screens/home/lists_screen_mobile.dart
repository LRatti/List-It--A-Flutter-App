import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';

class ListsScreenMobile extends StatefulWidget {
  final Function(VoidCallback)? onAddListCallback;

  const ListsScreenMobile({super.key, this.onAddListCallback});

  @override
  State<ListsScreenMobile> createState() => _ListsScreenMobileState();
}

class _ListsScreenMobileState extends State<ListsScreenMobile> {
  List<ShoppingList> _shoppingLists = [];

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
    // Expose the add method to parent via callback
    widget.onAddListCallback?.call(_showAddShoppingListDialog);
  }

  Future<void> _loadShoppingLists() async {
    final shoppingLists = await ManageShoppingList.getAllShoppingLists();
    setState(() {
      _shoppingLists = shoppingLists;
    });
  }

  void _showAddShoppingListDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add new list"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "List name"), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final newList = ShoppingList(
                  name: controller.text.trim(),
                  createdAt: DateTime.now(),
                );

                await ManageShoppingList.addShoppingList(newList);
              }
              
              Navigator.pop(context);
              await _loadShoppingLists();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditShoppingListDialog(ShoppingList list) {
    final controller = TextEditingController(text: list.getName());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit list"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "List name"), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                list.setName(controller.text.trim());
                await ManageShoppingList.updateShoppingList(list);
              }
              Navigator.pop(context);
              await _loadShoppingLists();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteShoppingList(ShoppingList list) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete list"),
        content: Text("Are you sure you want to delete '${list.getName()}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ManageShoppingList.deleteShoppingList(list);
              Navigator.pop(context);
              await _loadShoppingLists();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _shoppingLists.isEmpty
        ? const Center(child: Text("No lists yet.\nTap + to create one.", textAlign: TextAlign.center))
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.8),
            itemCount: _shoppingLists.length,
            itemBuilder: (context, index) {
              final shoppingList = _shoppingLists[index];
              return ShoppingListCard(
                shoppingList: shoppingList,
                onTap: () {}, // TODO: Implement detail screen
                onEdit: () => _showEditShoppingListDialog(shoppingList),
                onDelete: () => _deleteShoppingList(shoppingList),
              );
            },
          );
  }
}

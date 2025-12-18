import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/controllers/lists_controller.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';

/// Lists page showing all shopping lists with add/edit/delete functionality
class ListsScreenMobile extends StatefulWidget {
  final ListsController controller;

  const ListsScreenMobile({super.key, required this.controller});

  @override
  State<ListsScreenMobile> createState() => _ListsScreenMobileState();
}

class _ListsScreenMobileState extends State<ListsScreenMobile> {
  List<ShoppingList> _shoppingLists = [];
  bool _initialLoading = true; // suppress empty-state flicker on first load

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  Future<void> _loadShoppingLists() async {
    final lists = await widget.controller.loadLists();
    setState(() {
      _shoppingLists = lists;
      _initialLoading = false;
    });
  }

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

  Future<void> _updateListName(ShoppingList list, String newName) async {
    list.setName(newName);
    await widget.controller.updateList(list);
    await _loadShoppingLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initialLoading
          ? const SizedBox.shrink()
          : _shoppingLists.isEmpty
          ? const Center(
              child: Text(
                "No lists yet.\nTap + to create one.",
                textAlign: TextAlign.center,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Config for 3 columns
                const crossAxisCount = 3;
                const spacing = 12.0;

                // Calculate item width based on screen width
                final totalWidth = constraints.maxWidth;
                final itemWidth =
                    (totalWidth - (crossAxisCount + 1) * spacing) /
                    crossAxisCount;

                // Fixed heights for layout elements inside the card
                const nameRowHeight = 48.0; // Height of the name/delete row
                const verticalGap = 8.0; // Gap between yellow box and name
                const safeBuffer = 2.0; // Extra buffer

                // Total height calculation
                final itemHeight =
                    itemWidth + nameRowHeight + verticalGap + safeBuffer;

                return GridView.builder(
                  padding: const EdgeInsets.all(spacing),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: itemWidth / itemHeight,
                  ),
                  itemCount: _shoppingLists.length,
                  itemBuilder: (context, index) {
                    final shoppingList = _shoppingLists[index];
                    return ShoppingListCard(
                      shoppingList: shoppingList,
                      onTap: () {}, // TODO: implement detail screen
                      onNameChanged: (newName) =>
                          _updateListName(shoppingList, newName),
                      onDelete: () => _deleteShoppingList(shoppingList),
                    );
                  },
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

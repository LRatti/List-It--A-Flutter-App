import 'package:app_code/models/shopping_list.dart';
import 'package:flutter/material.dart';

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
    /*final shoppingLists = await DatabaseHelper.loadShoppingLists();
    setState(() => _shoppingLists = shoppingLists);*/
  }

  Future<void> _addShoppingList(String title) async {
    /*if (title.isEmpty) return;
    ShoppingList shoppingList;
    shoppingList.id = await DatabaseHelper.addShoppingList(shoppingList);
    setState(() => _shoppingLists.insert(0, shoppingList));*/
  }

  Future<void> _deleteShoppingList(int index) async {
    /*final note = _notes[index];
    if (note.id != null) await DatabaseHelper.deleteNote(note.id!);
    setState(() => _notes.removeAt(index));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Note '${note.title}' deleted.")));*/
  }

  Future<void> _editShoppingListTitle(int index) async {
    /*final note = _notes[index];
    TextEditingController controller = TextEditingController(text: note.title);

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
                note.title = controller.text;
                await DatabaseHelper.updateNote(note);
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );*/
  }

  void _openShoppingListDetail(ShoppingList shopping_list) {
    /*Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MobileNoteDetailPage(note: note)),
    ).then((_) => _loadNotes()); // ricarica le note quando ritorna*/
  }

  void _showAddShoppingListDialog() {
    /*TextEditingController controller = TextEditingController();

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
              _addNote(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );*/
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
                "No notes added yet. Tap '+' to add one!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // due note per riga
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8, // rettangolo verticale
              ),
              itemCount: _shoppingLists.length,
              itemBuilder: (context, index) {
                /*final note = _notes[index];
                return NoteCard(
                  note: note,
                  onTap: () => _openNoteDetail(note),
                  onEdit: () => _editNoteTitle(index),
                  onDelete: () => _deleteNote(index),
                );*/
                return null;
              },
            ),
    );
  }
}
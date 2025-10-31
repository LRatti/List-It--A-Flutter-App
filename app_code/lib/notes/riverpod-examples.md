class UserData {
  final String name;
  final int age;
  final int score;

  const UserData({
    required this.name,
    required this.age,
    required this.score,
  });

  // Copy with allows partial updates immutably
  UserData copyWith({String? name, int? age, int? score}) {
    return UserData(
      name: name ?? this.name,
      age: age ?? this.age,
      score: score ?? this.score,
    );
  }
}


// StateNotifier manages the state of UserData
class UserNotifier extends StateNotifier<UserData> {
  UserNotifier() : super(const UserData(name: 'John', age: 20, score: 0));

  void updateName(String newName) {
    state = state.copyWith(name: newName);
  }

  void incrementAge() {
    state = state.copyWith(age: state.age + 1);
  }

  void addScore(int points) {
    state = state.copyWith(score: state.score + points);
  }

  void reset() {
    state = const UserData(name: 'John', age: 20, score: 0);
  }
}

// Provider that exposes the notifier
final userProvider = StateNotifierProvider<UserNotifier, UserData>((ref) {
  return UserNotifier();
});


class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User Info')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Name: ${user.name}', style: const TextStyle(fontSize: 20)),
            Text('Age: ${user.age}', style: const TextStyle(fontSize: 20)),
            Text('Score: ${user.score}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditPage()),
              ),
              child: const Text('Edit User'),
            ),
          ],
        ),
      ),
    );
  }
}



class EditPage extends ConsumerWidget {
  const EditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: userNotifier.updateName,
              controller: TextEditingController(text: user.name),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => userNotifier.addScore(-10),
                ),
                Text('Score: ${user.score}', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => userNotifier.addScore(10),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: userNotifier.incrementAge,
              child: const Text('Increase Age'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: userNotifier.reset,
              child: const Text('Reset User'),
            ),
          ],
        ),
      ),
    );
  }
}

-------------------------------------------------------------------
// file: lib/providers/shopping_list_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'your_project/models/shopping_list.dart'; // Your ShoppingList class
// import 'your_project/services/database_helper.dart'; // Your SQFlite helper

// This class will hold our state (the list of shopping lists)
// and the logic to modify it.
class ShoppingListsNotifier extends StateNotifier<List<ShoppingList>> {
  // Initialize with an empty list. In a real app, you'd load this from the database.
  ShoppingListsNotifier() : super([]);

  // In a real app, you would have a method to load initial data
  Future<void> loadListsFromDatabase() async {
    // final lists = await DatabaseHelper.instance.getAllLists();
    // state = lists;
  }

  // --- METHODS TO MANIPULATE THE STATE ---

  // Method to add a new shopping list
  void addShoppingList(String name) {
    final newList = ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // A simple unique ID
      name: name,
      isCompleted: false,
    );
    
    // In a real app, you would save this to your sqflite database first
    // await DatabaseHelper.instance.insertList(newList);

    // This is the key part: we create a NEW list, which triggers an update.
    state = [...state, newList];
  }

  // Method to mark a list as complete
  void completeShoppingList(String listId) {
    // In a real app, you'd update the database first
    // await DatabaseHelper.instance.updateListStatus(listId, true);

    // Create a new list with the updated item
    state = [
      for (final list in state)
        if (list.id == listId)
          list.copyWith(isCompleted: true) // copyWith is a helper method in your model
        else
          list,
    ];
  }
}

// Finally, we create the global provider.
// This is what our UI will interact with.
final shoppingListsProvider = StateNotifierProvider<ShoppingListsNotifier, List<ShoppingList>>((ref) {
  return ShoppingListsNotifier();
});

// file: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_project/providers/shopping_list_provider.dart';

// Note: We use ConsumerWidget instead of StatelessWidget
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. "watch" the provider. This gets the data AND subscribes to changes.
    final allLists = ref.watch(shoppingListsProvider);

    // 2. Filter for only the active lists to display on the home screen.
    final activeLists = allLists.where((list) => !list.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: Text("My Shopping Lists")),
      body: ListView.builder(
        itemCount: activeLists.length,
        itemBuilder: (context, index) {
          final list = activeLists[index];
          return Card(
            child: ListTile(
              title: Text(list.name),
              // Tapping the list would navigate to the ShoppingListScreen(2)
              onTap: () { /* Navigate to list details */ },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 3. To modify the state, we get the "notifier" from the provider
          // and call one of its methods. We use 'read' inside callbacks.
          ref.read(shoppingListsProvider.notifier).addShoppingList("New List from Home");
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

// file: lib/screens/shopping_list_screen.dart (A simplified example)

// ... imports

class ShoppingListScreen extends ConsumerWidget {
  final String listId; // The ID of the list being viewed
  const ShoppingListScreen({required this.listId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return Scaffold(
      appBar: AppBar(title: Text("Editing List")),
      // ... list of products would be here ...
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          child: Text("Shopping Completed"),
          onPressed: () {
            // Call the method on the notifier to update the list's status.
            // We use 'ref.read' because we are in a callback ('onPressed').
            ref.read(shoppingListsProvider.notifier).completeShoppingList(listId);

            // After completing, go back to the home screen.
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
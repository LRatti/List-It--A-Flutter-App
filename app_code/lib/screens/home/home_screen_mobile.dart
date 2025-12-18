import 'package:flutter/material.dart';
import 'package:app_code/widgets/top_bar_with_navbar.dart';
import 'package:app_code/screens/home/lists_screen_mobile.dart';
import 'package:app_code/screens/home/supermarkets_screen_mobile.dart';
import 'package:app_code/screens/home/history_screen_mobile.dart';
import 'package:app_code/screens/home/statistics_screen_mobile.dart';
import 'package:app_code/controllers/lists_controller.dart';
import 'package:app_code/repositories/real_app/shopping_list_repository_sqlite.dart';

class MobileHomePage extends StatefulWidget {
  final ListsController? listsController;

  const MobileHomePage({super.key, this.listsController});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  int _selectedIndex = 0;

  /// Create a single controller instance with real repository (if not injected)
  late final ListsController _listsController = widget.listsController ?? ListsController(ShoppingListRepositorySqlite());

  /// Return the selected tab widget
  Widget _getSelectedTabContent() {
  switch (_selectedIndex) {
    case 0:
      return KeyedSubtree(
        key: const Key('lists_tab'),
        child: ListsScreenMobile(controller: _listsController),
      );
    case 1:
      return const KeyedSubtree(
        key: Key('history_tab'),
        child: HistoryScreenMobile(),
      );
    case 2:
      return const KeyedSubtree(
        key: Key('supermarkets_tab'),
        child: SupermarketsScreenMobile(),
      );
    case 3:
      return const KeyedSubtree(
        key: Key('statistics_tab'),
        child: StatisticsScreenMobile(),
      );
    default:
      return const SizedBox.shrink();
  }
}


  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBarWithNavBar(),
      body: _getSelectedTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Lists"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Supermarkets"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistics"),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:app_code/widgets/top_bar_with_navbar.dart';
import 'package:app_code/screens/home/lists_screen_mobile.dart';
import 'package:app_code/screens/home/supermarkets_screen_mobile.dart';
import 'package:app_code/screens/home/history_screen_mobile.dart';
import 'package:app_code/screens/home/statistics_screen_mobile.dart';

void main() {
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
  int _selectedIndex = 0;
  VoidCallback? _onAddListPressed;

  /// Return the selected tab widget
  Widget _getSelectedTabContent() {
    switch (_selectedIndex) {
      case 0:
        return ListsScreenMobile(
          onAddListCallback: (callback) => _onAddListPressed = callback,
        );
      case 1:
        return const HistoryScreenMobile();
      case 2:
        return const SupermarketsScreenMobile();
      case 3:
        return const StatisticsScreenMobile();
      default:
        return const Center(child: Text("Unknown tab"));
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _onAddListPressed?.call(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

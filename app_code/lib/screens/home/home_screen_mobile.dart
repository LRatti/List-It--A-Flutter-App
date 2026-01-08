import 'package:flutter/material.dart';
import 'package:app_code/widgets/top_bar_with_navbar.dart';
import 'package:app_code/screens/lists/lists_screen_mobile.dart';
import 'package:app_code/screens/supermarket/supermarkets_screen_mobile.dart';
import 'package:app_code/screens/history/history_screen_mobile.dart';
import 'package:app_code/screens/stats/statistics_screen_mobile.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  int _selectedIndex = 0;

  // Helper to switch between content screens
  Widget _getSelectedTabContent() {
    switch (_selectedIndex) {
      case 0:
        return const ListsScreenMobile(key: ValueKey('lists_tab'));
      case 1:
        return const HistoryScreenMobile(key: ValueKey('history_tab'));
      case 2:
        return const SupermarketsScreenMobile(key: ValueKey('supermarkets_tab'));
      case 3:
        return const StatisticsScreenMobile(key: ValueKey('statistics_tab'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      // Standard Top Bar across all views
      appBar: const TopBarWithNavBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // NavigationRail only visible in Landscape
          if (isLandscape)
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: SafeArea(
                child: NavigationRail(
                  backgroundColor: const Color(0xFFF7F9FC),
                  minWidth: 72,
                  labelType: NavigationRailLabelType.all,
                  scrollable: true ,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  groupAlignment: 0.0,
                  selectedIconTheme: const IconThemeData(color: Colors.blue),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
                  selectedLabelTextStyle: const TextStyle(color: Colors.blue),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                  useIndicator: true,
                  indicatorColor: Colors.blue.shade50,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.list_outlined),
                      selectedIcon: Icon(Icons.list),
                      label: Text("Lists"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: Text("History"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.store_outlined),
                      selectedIcon: Icon(Icons.store),
                      label: Text("Supermarkets"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text("Statistics"),
                    ),
                  ],
                ),
              ),
            ),
          
          // Vertical divider to separate NavRail from content
          if (isLandscape) const VerticalDivider(thickness: 1, width: 1),

          // Main Content Area
          Expanded(child: _getSelectedTabContent()),
        ],
      ),
      
      // Bottom Navigation Bar only visible in Portrait
      bottomNavigationBar: isLandscape
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
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
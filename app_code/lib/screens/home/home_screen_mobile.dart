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

  final List<Widget> _tabs = const [
    ListsScreenMobile(key: ValueKey('lists_tab')),
    HistoryScreenMobile(key: ValueKey('history_tab')),
    SupermarketsScreenMobile(key: ValueKey('supermarkets_tab')),
    StatisticsScreenMobile(key: ValueKey('statistics_tab')),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Fully dynamic top bar
            const TopBarWithNavBar(),

            // Main content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLandscape)
                    Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: NavigationRail(
                        backgroundColor: const Color(0xFFF7F9FC),
                        minWidth: 72,
                        labelType: NavigationRailLabelType.all,
                        selectedIndex: _selectedIndex,
                        scrollable: true ,
                        onDestinationSelected: (int index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        selectedIconTheme:
                            const IconThemeData(color: Colors.blue),
                        unselectedIconTheme:
                            const IconThemeData(color: Colors.grey),
                        selectedLabelTextStyle:
                            const TextStyle(color: Colors.blue),
                        unselectedLabelTextStyle:
                            const TextStyle(color: Colors.grey),
                        useIndicator: true,
                        indicatorColor:
                            Colors.blueAccent.withOpacity(0.1),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.list_outlined),
                            selectedIcon: Icon(Icons.list),
                            label: Text('Lists'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.history_outlined),
                            selectedIcon: Icon(Icons.history),
                            label: Text('History'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.store_outlined),
                            selectedIcon: Icon(Icons.store),
                            label: Text('Supermarkets'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.bar_chart_outlined),
                            selectedIcon: Icon(Icons.bar_chart),
                            label: Text('Statistics'),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _tabs,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation only in portrait
      bottomNavigationBar: isLandscape
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Lists',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.store),
                  label: 'Supermarkets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Statistics',
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/top_bar_with_navbar.dart';
import 'package:app_code/screens/lists/lists_screen_mobile.dart';
import 'package:app_code/screens/supermarket/supermarkets_screen_mobile.dart';
import 'package:app_code/screens/history/history_screen_mobile.dart';
import 'package:app_code/screens/stats/statistics_screen_mobile.dart';
import 'package:app_code/providers/text_scale_provider.dart';

class MobileHomePage extends ConsumerStatefulWidget {
  const MobileHomePage({super.key});

  @override
  ConsumerState<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends ConsumerState<MobileHomePage> {
  int _selectedIndex = 0;

  Widget _getSelectedTabContent() {
    switch (_selectedIndex) {
      case 0:
        return const KeyedSubtree(
          key: Key('lists_tab'),
          child: ListsScreenMobile(),
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
    final textScale = ref.watch(textScaleProvider);
    final iconSize = (24.0 * textScale).clamp(20.0, 32.0);
    
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
        iconSize: iconSize,
        selectedFontSize: (14.0 * textScale).clamp(12.0, 18.0),
        unselectedFontSize: (12.0 * textScale).clamp(10.0, 16.0),
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

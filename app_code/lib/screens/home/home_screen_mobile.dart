import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/top_bar_with_navbar.dart';
import 'package:app_code/widgets/side_menu.dart';
import 'package:app_code/screens/lists/lists_screen_mobile.dart';
import 'package:app_code/screens/supermarket/supermarkets_screen_mobile.dart';
import 'package:app_code/screens/history/history_screen_mobile.dart';
import 'package:app_code/screens/stats/statistics_screen_mobile.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';

class MobileHomePage extends ConsumerStatefulWidget {
  const MobileHomePage({super.key});

  @override
  ConsumerState<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends ConsumerState<MobileHomePage> {
  bool _isMenuOpen = false;
  bool _didApplyRouteArgs = false;

  final List<Widget> _tabs = const [
    ListsScreenMobile(key: ValueKey('lists_tab')),
    HistoryScreenMobile(key: ValueKey('history_tab')),
    SupermarketsScreenMobile(key: ValueKey('supermarkets_tab')),
    StatisticsScreenMobile(key: ValueKey('statistics_tab')),
  ];

  void _toggleMenu() {
    ref.read(appNavigationSignalProvider.notifier).state++;
    setState(() => _isMenuOpen = !_isMenuOpen);
  }
  void _closeMenu() {
    ref.read(appNavigationSignalProvider.notifier).state++;
    setState(() => _isMenuOpen = false);
  }

  void _onTabChanged(int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
    ref.read(appNavigationSignalProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    // // Listen to navigation intent and apply it after frame rendering
    ref.listen<HomeTab?>(homeTabNavigationIntentProvider, (previous, next) {
      if (next == null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetIndex = homeTabIndex[next] ?? 0;
        if (mounted && ref.read(navigationIndexProvider) != targetIndex) {
          ref.read(navigationIndexProvider.notifier).state = targetIndex;
        }

        // Reset intent after consuming it
        if (mounted) {
          ref.read(homeTabNavigationIntentProvider.notifier).state = null;
        }
      });
    });

    // Check for route arguments on first build
    if (!_didApplyRouteArgs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final routeArgs = ModalRoute.of(context)?.settings.arguments;
        final currentIntent = ref.read(homeTabNavigationIntentProvider);
        if (routeArgs is HomeTab && currentIntent == null && mounted) {
          ref.read(homeTabNavigationIntentProvider.notifier).state = routeArgs;
        }
      });
      _didApplyRouteArgs = true;
    }

    final selectedIndex = ref.watch(navigationIndexProvider);
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopBarWithNavBar(
                  isMenuOpen: _isMenuOpen,
                  onMenuToggle: _toggleMenu,
                ),

                // Main content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isLandscape)
                        Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            border: Border(
                              right: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                          ),
                          child: NavigationRail(
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            minWidth: 72,
                            labelType: NavigationRailLabelType.all,
                            selectedIndex: selectedIndex,
                            scrollable: true,
                            onDestinationSelected: (int index) =>
                              _onTabChanged(index),
                            selectedIconTheme:
                                IconThemeData(color: colorScheme.primary),
                            unselectedIconTheme:
                                IconThemeData(color: colorScheme.onSurfaceVariant),
                            selectedLabelTextStyle:
                                TextStyle(color: colorScheme.primary),
                            unselectedLabelTextStyle:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                            useIndicator: true,
                            indicatorColor: colorScheme.primaryContainer, // subtle indicator
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
                          index: selectedIndex,
                          children: _tabs,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Side menu overlay
            if (_isMenuOpen)
              Positioned(
                top: kToolbarHeight + 56,
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  children: [
                    SideMenu(
                      key: const Key('side_menu'),
                      onClose: _closeMenu,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _closeMenu,
                        child: Container(
                          key: const Key('side_menu_scrim'),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
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
        currentIndex: selectedIndex,
        onTap: (int index) => _onTabChanged(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface, // solid background
        selectedItemColor: Theme.of(context).colorScheme.primary, // bright/visible
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold), // make selected label bold
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Supermarkets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),

    );
  }
}

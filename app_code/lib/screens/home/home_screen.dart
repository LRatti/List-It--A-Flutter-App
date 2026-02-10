import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/widgets/top_bar_with_navbar.dart';
import 'package:app_code/widgets/side_menu.dart';
import 'package:app_code/screens/lists/lists_screen.dart';
import 'package:app_code/screens/supermarket/supermarkets_screen.dart';
import 'package:app_code/screens/history/history_screen.dart';
import 'package:app_code/screens/stats/statistics_screen.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';

/// Home screen with responsive layout: bottom navigation bar on mobile, 
/// navigation rail on tablet.
class HomeScreenMobileView extends ConsumerStatefulWidget {
  const HomeScreenMobileView({super.key});

  @override
  ConsumerState<HomeScreenMobileView> createState() => _HomeScreenMobileViewState();
}

/// Home screen with responsive layout: bottom navigation bar on mobile, 
/// navigation rail on tablet.
class HomeScreenTabletView extends ConsumerStatefulWidget {
  const HomeScreenTabletView({super.key});

  @override
  ConsumerState<HomeScreenTabletView> createState() => _HomeScreenTabletViewState();
}

/// Base state class for home screen, shared by both mobile and tablet layouts. 
abstract class _HomeScreenBaseState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  bool _isMenuOpen = false;
  bool _didApplyRouteArgs = false;

  List<Widget> get tabs;
  bool get shouldCloseMenuOnTabChange;

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
    if (shouldCloseMenuOnTabChange && _isMenuOpen) {
      _closeMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to navigation intent and apply it after frame rendering
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
    final colorScheme = Theme.of(context).colorScheme;

    return buildScaffold(context, selectedIndex, colorScheme);
  }

  Widget buildScaffold(
    BuildContext context,
    int selectedIndex,
    ColorScheme colorScheme,
  );

  /// Build the bottom navigation bar for mobile screens
  Widget _buildBottomNavigationBar(
    ColorScheme colorScheme,
    int selectedIndex,
    AppLocalizations l10n,
  ) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (int index) => _onTabChanged(index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.list_outlined),
          activeIcon: const Icon(Icons.list),
          label: l10n.listsTabLabel,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_outlined),
          activeIcon: const Icon(Icons.history),
          label: l10n.historyTabLabel,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.store_outlined),
          activeIcon: const Icon(Icons.store),
          label: l10n.supermarketsTabLabel,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart_outlined),
          activeIcon: const Icon(Icons.bar_chart),
          label: l10n.statisticsTabLabel,
        ),
      ],
    );
  }

  /// Build the persistent navigation rail for tablet/desktop screens
  Widget _buildNavigationRail(
    ColorScheme colorScheme,
    int selectedIndex,
    AppLocalizations l10n,
  ) {
    return Container(
      width: 140,
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
        minWidth: 132,
        labelType: NavigationRailLabelType.all,
        selectedIndex: selectedIndex,
        scrollable: true,
        onDestinationSelected: (int index) => _onTabChanged(index),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        useIndicator: true,
        indicatorColor: colorScheme.primaryContainer,
        destinations: [
          NavigationRailDestination(
            icon: const Icon(Icons.list_outlined),
            selectedIcon: const Icon(Icons.list),
            label: Text(l10n.listsTabLabel),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: Text(l10n.historyTabLabel),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.store_outlined),
            selectedIcon: const Icon(Icons.store),
            label: Text(l10n.supermarketsTabLabel),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: Text(l10n.statisticsTabLabel),
          ),
        ],
      ),
    );
  }
}

/// Mobile layout: single pane with bottom navigation
class _HomeScreenMobileViewState
    extends _HomeScreenBaseState<HomeScreenMobileView> {
  @override
  List<Widget> get tabs => const [
        ListsScreenMobile(key: ValueKey('lists_tab')),
        HistoryScreenMobile(key: ValueKey('history_tab')),
        SupermarketsScreenMobile(key: ValueKey('supermarkets_tab')),
        StatisticsScreenMobile(key: ValueKey('statistics_tab')),
      ];

  @override
  bool get shouldCloseMenuOnTabChange => true;

  @override
  Widget buildScaffold(
    BuildContext context,
    int selectedIndex,
    ColorScheme colorScheme,
  ) {
    final l10n = AppLocalizations.of(context)!;

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
                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: tabs,
                  ),
                ),
              ],
            ),
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
      bottomNavigationBar: _buildBottomNavigationBar(
        colorScheme,
        selectedIndex,
        l10n,
      ),
    );
  }
}

/// Tablet layout: master-detail split view with navigation rail
class _HomeScreenTabletViewState
    extends _HomeScreenBaseState<HomeScreenTabletView> {
  @override
  List<Widget> get tabs => const [
        ListsScreenTablet(key: ValueKey('lists_tab')),
        HistoryScreenTablet(key: ValueKey('history_tab')),
        SupermarketsScreenTablet(key: ValueKey('supermarkets_tab')),
        StatisticsScreenTablet(key: ValueKey('statistics_tab')),
      ];

  @override
  bool get shouldCloseMenuOnTabChange => false;

  @override
  Widget buildScaffold(
    BuildContext context,
    int selectedIndex,
    ColorScheme colorScheme,
  ) {
    final l10n = AppLocalizations.of(context)!;

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
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNavigationRail(colorScheme, selectedIndex, l10n),
                      Expanded(
                        child: IndexedStack(
                          index: selectedIndex,
                          children: tabs,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    );
  }
}

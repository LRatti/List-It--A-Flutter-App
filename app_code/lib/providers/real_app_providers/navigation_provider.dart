import 'package:flutter_riverpod/legacy.dart';

enum HomeTab {
	lists,
	history,
	supermarkets,
	statistics,
}

const homeTabIndex = {
	HomeTab.lists: 0,
	HomeTab.history: 1,
	HomeTab.supermarkets: 2,
	HomeTab.statistics: 3,
};

/// Global provider to track the currently active tab index in MobileHomePage.
/// This allows other widgets to know which tab is currently visible and reset
/// their state when the user navigates away.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Intent to navigate to a specific Home tab. Consumed once by MobileHomePage.
final homeTabNavigationIntentProvider = StateProvider<HomeTab?>((ref) => null);

/// Broadcast signal to let views reset local UI state on navigation changes.
final appNavigationSignalProvider = StateProvider<int>((ref) => 0);

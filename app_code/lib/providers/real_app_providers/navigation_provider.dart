import 'package:flutter_riverpod/legacy.dart';

/// Global provider to track the currently active tab index in MobileHomePage.
/// This allows other widgets to know which tab is currently visible and reset
/// their state when the user navigates away.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Broadcast signal to let views reset local UI state on navigation changes.
final appNavigationSignalProvider = StateProvider<int>((ref) => 0);

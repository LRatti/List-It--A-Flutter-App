import 'package:flutter/material.dart';

/// A widget that wraps content in its own Navigator for master-detail layouts.
/// 
/// This keeps all navigation within the detail pane isolated from the main
/// app navigation, ensuring that pushed screens stay within the detail pane
/// instead of occupying the full screen.
/// 
/// Used in tablet/desktop layouts to maintain the master-detail split view
/// during navigation.
/// 
/// The navigator starts with an empty route and pushes the initial child as
/// the first route, allowing users to navigate back to an empty state.
class DetailPaneNavigator extends StatefulWidget {
  final Widget initialChild;
  final Widget Function(BuildContext) emptyBuilder;

  const DetailPaneNavigator({
    super.key,
    required this.initialChild,
    required this.emptyBuilder,
  });

  @override
  State<DetailPaneNavigator> createState() => _DetailPaneNavigatorState();
}

class _DetailPaneNavigatorState extends State<DetailPaneNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void didUpdateWidget(DetailPaneNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // When the initialChild changes (different list selected), 
    // clear the navigation stack and push the new child
    if (oldWidget.initialChild != widget.initialChild) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => widget.initialChild,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => widget.emptyBuilder(context),
        );
      },
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          MaterialPageRoute(
            builder: (context) => widget.emptyBuilder(context),
          ),
          MaterialPageRoute(
            builder: (context) => widget.initialChild,
          ),
        ];
      },
    );
  }
}

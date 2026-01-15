import 'package:flutter/material.dart';

/// A wrapper widget that adds safe padding to avoid being covered by
/// Android's navigation bar or other system UI elements.
///
/// In portrait orientation, adds bottom padding.
/// In landscape orientation, adds left/right padding depending on navigation bar position.
/// This is useful for buttons and other UI elements that are positioned at
/// the bottom or sides of the screen and need to be accessible.
///
/// Example usage:
/// ```dart
/// SafeBottomPaddingWrapper(
///   child: ElevatedButton(
///     onPressed: () {},
///     child: const Text('Button'),
///   ),
/// )
/// ```
class SafeBottomPaddingWrapper extends StatelessWidget {
  final Widget child;
  final double defaultPadding;

  const SafeBottomPaddingWrapper({
    super.key,
    required this.child,
    this.defaultPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewPadding = mediaQuery.viewPadding;
    
    // Use viewPadding which represents system UI insets regardless of SafeArea
    // This ensures proper padding in both portrait and landscape
    return Padding(
      padding: EdgeInsets.fromLTRB(
        defaultPadding + viewPadding.left,
        defaultPadding,
        defaultPadding + viewPadding.right,
        defaultPadding + viewPadding.bottom,
      ),
      child: child,
    );
  }
}

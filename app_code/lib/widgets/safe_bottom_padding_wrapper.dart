import 'package:flutter/material.dart';

/// A wrapper widget that adds safe bottom padding to avoid being covered by
/// Android's navigation bar or other system UI elements.
///
/// This is useful for buttons and other UI elements that are positioned at
/// the bottom of the screen and need to be accessible.
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding + defaultPadding),
      child: Padding(
        padding: EdgeInsets.fromLTRB(defaultPadding, defaultPadding, defaultPadding, 0),
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:app_code/utils/screen_size_helper.dart';
import 'package:app_code/providers/real_app_providers/screen_size_provider.dart';

/// Widget that monitors MediaQuery changes and updates the screen size provider.
/// 
/// This widget should be placed near the top of the widget tree (typically wrapping
/// the entire app or main content) to ensure all responsive widgets below it can
/// watch the screen size provider and rebuild automatically when size changes.
///
/// Features:
/// - Detects screen size changes on device rotation
/// - Detects orientation changes
/// - Detects transitions between mobile/tablet/desktop
/// - Notifies all watching widgets of size changes
/// - Debounces updates to prevent excessive rebuilds
///
/// Usage in main.dart or your app wrapper:
/// ```dart
/// return AppScreenSizeListener(
///   child: MaterialApp(
///     // ... your app ...
///   ),
/// );
/// ```
class AppScreenSizeListener extends ConsumerStatefulWidget {
  final Widget child;

  const AppScreenSizeListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppScreenSizeListener> createState() =>
      _AppScreenSizeListenerState();
}

class _AppScreenSizeListenerState extends ConsumerState<AppScreenSizeListener>
    with WidgetsBindingObserver {
  late ScreenClassification _lastKnownClassification;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize with unknown to force first measurement to trigger update
    _lastKnownClassification = ScreenClassification.unknown;
    
    // Schedule screen size measurement after the widget tree is built
    // This prevents modifying the provider during the build lifecycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateScreenSizeFromWindow();
        _updateScreenSize();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Update screen size using window metrics (available before MediaQuery)
  /// This is called in initState before MaterialApp has built its MediaQuery
  void _updateScreenSizeFromWindow() {
    final window = WidgetsBinding.instance.window;
    final size = window.physicalSize / window.devicePixelRatio;
    
    final newClassification = _classifySize(size.width);
    
    // Force update even if "unknown" → actual (provides initial state change)
    if (_lastKnownClassification != newClassification) {
      _lastSize = size;
      _lastKnownClassification = newClassification;
      
      ref
          .read(screenSizeProvider.notifier)
          .updateScreenSize(newClassification);
    }
  }

  /// Classify screen based on width
  ScreenClassification _classifySize(double width) {
    if (width < ScreenSize.tabletMin) {
      return ScreenClassification.mobile;
    } else if (width < ScreenSize.desktopMin) {
      return ScreenClassification.tablet;
    } else if (width < ScreenSize.largeDesktopMin) {
      return ScreenClassification.desktop;
    } else {
      return ScreenClassification.largeDesktop;
    }
  }

  /// Update the screen size provider based on current BuildContext (uses MediaQuery)
  void _updateScreenSize() {
    if (!mounted) return;

    final newSize = MediaQuery.of(context).size;
    final newClassification = ScreenSize.classify(context);

    // Only update if size or classification actually changed
    if (_lastSize != newSize ||
        _lastKnownClassification != newClassification) {
      _lastSize = newSize;
      _lastKnownClassification = newClassification;

      // Update the provider to notify all watchers
      ref
          .read(screenSizeProvider.notifier)
          .updateScreenSize(newClassification);
    }
  }

  /// Called when app lifecycle changes (e.g., comes to foreground).
  /// Recheck screen size in case it changed while app was backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateScreenSize();
        }
      });
    }
  }

  /// Called when the screen metrics (size, orientation, etc.) change.
  /// This is the primary callback we use for responsive behavior.
  @override
  void didChangeMetrics() {
    // Schedule update on next frame to ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScreenSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A simpler alternative: Wraps the app's Navigator or route to listen for size changes
/// Use this if you prefer to place the listener lower in the widget tree
class ResponsiveLayoutOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const ResponsiveLayoutOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ResponsiveLayoutOverlay> createState() =>
      _ResponsiveLayoutOverlayState();
}

class _ResponsiveLayoutOverlayState extends ConsumerState<ResponsiveLayoutOverlay> {
  @override
  Widget build(BuildContext context) {
    // Watch the screen size provider to ensure rebuilds
    ref.watch(screenSizeProvider);

    // Return a widget that listens to size changes
    return _ScreenSizeAwareBuilder(
      onSizeChanged: (classification) {
        ref.read(screenSizeProvider.notifier).updateScreenSize(classification);
      },
      child: widget.child,
    );
  }
}

/// Internal widget that rebuilds when size changes
/// Used to detect and propagate size changes to the provider
class _ScreenSizeAwareBuilder extends StatefulWidget {
  final Widget child;
  final Function(ScreenClassification) onSizeChanged;

  const _ScreenSizeAwareBuilder({
    required this.child,
    required this.onSizeChanged,
  });

  @override
  State<_ScreenSizeAwareBuilder> createState() =>
      _ScreenSizeAwareBuilderState();
}

class _ScreenSizeAwareBuilderState extends State<_ScreenSizeAwareBuilder> {
  late ScreenClassification _currentClassification;

  @override
  void initState() {
    super.initState();
    _currentClassification = ScreenSize.classify(context);
  }

  @override
  Widget build(BuildContext context) {
    final newClassification = ScreenSize.classify(context);

    // Update parent when size changes
    if (newClassification != _currentClassification) {
      _currentClassification = newClassification;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onSizeChanged(newClassification);
        }
      });
    }

    return widget.child;
  }
}

import 'package:flutter/material.dart';

/// Screen size breakpoints and helper utilities for responsive design.
/// 
/// This module provides consistent screen size classification and responsive
/// layout helpers across the entire app, ensuring a unified responsive behavior.
class ScreenSize {
  /// Mobile breakpoint - smartphones typically < 600 dp
  static const double mobileMax = 1200.0;

  /// dp (density-independent pixels) is a unit of measurement used in Android and Flutter development.
  /// It represents logical pixels that scale based on the device's screen density.
  /// This ensures consistent UI sizing across devices with different physical screen sizes and pixel densities.
  /// For example, a 600 dp width will appear roughly the same size on phones with different DPI values.
  /// Tablet breakpoint - tablets typically 600-900 dp
  static const double tabletMin = 1200.0;
  static const double tabletMax = 1600.0;

  /// Desktop breakpoint - large screens >= 900 dp
  static const double desktopMin = 1600.0;

  /// Large desktop - very large screens >= 1200 dp
  static const double largeDesktopMin = 1800.0;

  // Immutable at-launch classification (phone vs tablet+)
  static bool? _isTabletAtLaunch;

  /// True if the app started on a tablet-sized screen (tablet or larger)
  static bool? get isTabletAtLaunch => _isTabletAtLaunch;

  /// True if the app started on a phone-sized screen
  static bool? get isPhoneAtLaunch =>
      _isTabletAtLaunch == null ? null : !_isTabletAtLaunch!;

  /// Initialize the at-launch device type using a raw width.
  /// This is intentionally one-shot and will not change after first set.
  static void initializeDeviceTypeFromWidth(double width) {
    _isTabletAtLaunch ??= width >= tabletMin;
    if(isTabletAtLaunch == true) {
      debugPrint('Tablet');
    } else {
      debugPrint('Phone');
    }
  }

  /// Get the current screen width
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get the current screen height
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if the current screen is in mobile size range
  static bool isMobile(BuildContext context) {
    return getWidth(context) < tabletMin;
  }

  /// Check if the current screen is in tablet size range (portrait or landscape)
  static bool isTablet(BuildContext context) {
    final width = getWidth(context);
    return width >= tabletMin && width < desktopMin;
  }

  /// Check if the current screen is in desktop size range
  static bool isDesktop(BuildContext context) {
    return getWidth(context) >= desktopMin;
  }

  /// Check if the current screen is in large desktop size range
  static bool isLargeDesktop(BuildContext context) {
    return getWidth(context) >= largeDesktopMin;
  }

  /// Determine screen classification
  static ScreenClassification classify(BuildContext context) {
    final width = getWidth(context);
    if (width < tabletMin) {
      return ScreenClassification.mobile;
    } else if (width < desktopMin) {
      return ScreenClassification.tablet;
    } else if (width < largeDesktopMin) {
      return ScreenClassification.desktop;
    } else {
      return ScreenClassification.largeDesktop;
    }
  }

  /// Get orientation
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// Check if currently in landscape
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == Orientation.landscape;
  }

  /// Check if currently in portrait
  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == Orientation.portrait;
  }

  /// Get device pixel ratio (for scaling)
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Get top padding (for safe area)
  static double getTopPadding(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get bottom padding (for safe area, notches)
  static double getBottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return getKeyboardHeight(context) > 0;
  }
}

/// Screen size classification enum
enum ScreenClassification {
  mobile,
  tablet,
  desktop,
  largeDesktop,
  unknown; // Sentinel value to force initial state update

  /// Get human-readable name
  String get displayName {
    switch (this) {
      case ScreenClassification.mobile:
        return 'Mobile';
      case ScreenClassification.tablet:
        return 'Tablet';
      case ScreenClassification.desktop:
        return 'Desktop';
      case ScreenClassification.largeDesktop:
        return 'Large Desktop';
      case ScreenClassification.unknown:
        return 'Unknown';
    }
  }
}

/// Responsive spacing and sizing constants that scale with screen size
class ResponsiveSpacing {
  /// Get responsive horizontal padding based on screen size
  static double getHorizontalPadding(BuildContext context) {
    final width = ScreenSize.getWidth(context);
    if (width < 600) return 16.0; // Mobile
    if (width < 900) return 24.0; // Tablet
    if (width < 1200) return 32.0; // Desktop
    return 48.0; // Large desktop
  }

  /// Get responsive vertical padding based on screen size
  static double getVerticalPadding(BuildContext context) {
    final width = ScreenSize.getWidth(context);
    if (width < 600) return 12.0; // Mobile
    if (width < 900) return 16.0; // Tablet
    if (width < 1200) return 20.0; // Desktop
    return 24.0; // Large desktop
  }

  /// Get responsive corner radius
  static double getCornerRadius(BuildContext context) {
    if (ScreenSize.isMobile(context)) return 8.0;
    if (ScreenSize.isTablet(context)) return 12.0;
    return 16.0;
  }

  /// Get responsive gap between elements
  static double getGap(BuildContext context) {
    if (ScreenSize.isMobile(context)) return 8.0;
    if (ScreenSize.isTablet(context)) return 12.0;
    return 16.0;
  }

  /// Get responsive item spacing (larger gaps)
  static double getItemSpacing(BuildContext context) {
    if (ScreenSize.isMobile(context)) return 12.0;
    if (ScreenSize.isTablet(context)) return 16.0;
    return 20.0;
  }
}

/// Responsive column width helpers for multi-column layouts
class ResponsiveColumns {
  /// Get number of grid columns based on screen size
  /// Mobile: 1, Tablet: 2, Desktop: 3+
  static int getGridColumns(BuildContext context) {
    final width = ScreenSize.getWidth(context);
    if (width < 600) return 1; // Mobile
    if (width < 900) return 2; // Tablet
    if (width < 1200) return 3; // Desktop
    return 4; // Large desktop
  }

  /// Get optimal width for a detail pane on tablets/desktop
  /// Returns null for mobile (full width), otherwise returns fixed width
  static double? getDetailPaneWidth(BuildContext context) {
    final width = ScreenSize.getWidth(context);
    if (width < 600) return null; // Mobile - full width
    if (width < 900) return 350; // Tablet - fixed width
    if (width < 1200) return 400; // Desktop
    return 450; // Large desktop
  }

  /// Get optimal width for a list pane on split view layouts
  /// Typically the remaining space after detail pane
  static double getListPaneMinWidth(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return ScreenSize.getWidth(context); // Full width on mobile
    }
    return 300; // Minimum width for list pane on tablets/desktop
  }

  /// Get optimal master-detail split ratio (master percentage)
  /// Mobile: 100%, Tablet: 40%, Desktop: 35%
  static double getMasterDetailRatio(BuildContext context) {
    if (ScreenSize.isMobile(context)) return 1.0; // 100%
    if (ScreenSize.isTablet(context)) return 0.4; // 40%
    return 0.35; // 35% on desktop
  }
}

/// Responsive breakpoint listeners for rebuilding on size changes
/// Use this mixin in StatefulWidget to listen to size changes
mixin ResponsiveWidgetMixin<T extends StatefulWidget> on State<T> {
  /// Called when screen size changes
  void onScreenSizeChanged(ScreenSize newSize) {}

  /// Get current screen classification
  ScreenClassification get screenClassification {
    return ScreenSize.classify(context);
  }

  /// Get current screen width
  double get screenWidth {
    return ScreenSize.getWidth(context);
  }

  /// Check if mobile
  bool get isMobile {
    return ScreenSize.isMobile(context);
  }

  /// Check if tablet
  bool get isTablet {
    return ScreenSize.isTablet(context);
  }

  /// Check if desktop
  bool get isDesktop {
    return ScreenSize.isDesktop(context);
  }
}

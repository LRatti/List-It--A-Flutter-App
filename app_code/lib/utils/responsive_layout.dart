import 'package:flutter/material.dart';
import 'package:app_code/utils/screen_size_helper.dart';

/// Reusable responsive layout widgets and helpers for building
/// adaptive UIs that work across mobile, tablet, and desktop.

/// A responsive container that adjusts its properties based on screen size.
/// 
/// Example:
/// ```dart
/// ResponsiveContainer(
///   mobile: (context) => Padding(padding: EdgeInsets.all(16), child: content),
///   tablet: (context) => Padding(padding: EdgeInsets.all(24), child: content),
///   desktop: (context) => Padding(padding: EdgeInsets.all(32), child: content),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveContainer({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return mobile(context);
    } else if (ScreenSize.isTablet(context) && tablet != null) {
      return tablet!(context);
    } else if (ScreenSize.isDesktop(context) && desktop != null) {
      return desktop!(context);
    }
    
    // Fallback to mobile if specific builder not provided
    return mobile(context);
  }
}

/// A responsive grid that adapts the number of columns based on screen size.
/// 
/// Automatically adjusts column count:
/// - Mobile: 1 column
/// - Tablet: 2 columns
/// - Desktop: 3-4 columns
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double? spacing;
  final EdgeInsets? padding;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.spacing,
    this.padding,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? ResponsiveSpacing.getGap(context);
    final pad = padding ?? EdgeInsets.all(ResponsiveSpacing.getHorizontalPadding(context));
    
    int crossAxisCount = ResponsiveColumns.getGridColumns(context);
    
    // Override with custom values if provided
    if (ScreenSize.isMobile(context) && mobileColumns != null) {
      crossAxisCount = mobileColumns!;
    } else if (ScreenSize.isTablet(context) && tabletColumns != null) {
      crossAxisCount = tabletColumns!;
    } else if (ScreenSize.isDesktop(context) && desktopColumns != null) {
      crossAxisCount = desktopColumns!;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      padding: pad,
      children: children,
    );
  }
}

/// A responsive master-detail layout widget.
/// 
/// On mobile: Shows only the master view (full width)
/// On tablet/desktop: Shows master and detail side-by-side
/// 
/// Example:
/// ```dart
/// ResponsiveMasterDetail(
///   masterBuilder: (context) => ListView(...),
///   detailBuilder: (context) => DetailContent(...),
///   detailVisible: _selectedItem != null,
///   onDetailClose: () => setState(() => _selectedItem = null),
/// )
/// ```
class ResponsiveMasterDetail extends StatelessWidget {
  final Widget Function(BuildContext context) masterBuilder;
  final Widget Function(BuildContext context)? detailBuilder;
  final bool detailVisible;
  final VoidCallback? onDetailClose;
  final double? masterWidthRatio;

  const ResponsiveMasterDetail({
    super.key,
    required this.masterBuilder,
    this.detailBuilder,
    this.detailVisible = true,
    this.onDetailClose,
    this.masterWidthRatio,
  });

  @override
  Widget build(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      // Mobile: Full-screen master or detail
      if (detailVisible && detailBuilder != null) {
        return Stack(
          children: [
            detailBuilder!(context),
            if (onDetailClose != null)
              Positioned(
                top: 16,
                left: 16,
                child: FloatingActionButton.small(
                  onPressed: onDetailClose,
                  child: const Icon(Icons.close),
                ),
              ),
          ],
        );
      }
      return masterBuilder(context);
    }

    // Tablet/Desktop: Split view
    final masterRatio = masterWidthRatio ?? ResponsiveColumns.getMasterDetailRatio(context);
    
    if (detailBuilder == null || !detailVisible) {
      return masterBuilder(context);
    }

    return Row(
      children: [
        Flexible(
          flex: (masterRatio * 100).toInt(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
            ),
            child: masterBuilder(context),
          ),
        ),
        Flexible(
          flex: ((1 - masterRatio) * 100).toInt(),
          child: detailBuilder!(context),
        ),
      ],
    );
  }
}

/// A responsive wrapper that shows content in full-width on mobile
/// and in a constrained width on larger screens.
class ResponsiveMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  const ResponsiveMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return child;
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A responsive row that stacks vertically on mobile and horizontally on larger screens.
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children
            .expand((child) => [child, SizedBox(height: spacing)])
            .toList()
          ..removeLast(), // Remove last spacing
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children
          .expand((child) => [child, SizedBox(width: spacing)])
          .toList()
        ..removeLast(), // Remove last spacing
    );
  }
}

/// A responsive navigation bar that becomes a drawer on mobile.
/// 
/// Shows a persistent side navigation on tablet/desktop and a drawer
/// toggle button on mobile.
class ResponsiveNavigationLayout extends StatefulWidget {
  final Widget Function(BuildContext context) contentBuilder;
  final PreferredSizeWidget? appBar;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color? backgroundColor;

  const ResponsiveNavigationLayout({
    super.key,
    required this.contentBuilder,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.appBar,
    this.backgroundColor,
  });

  @override
  State<ResponsiveNavigationLayout> createState() =>
      _ResponsiveNavigationLayoutState();
}

class _ResponsiveNavigationLayoutState extends State<ResponsiveNavigationLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      // Mobile: Use drawer
      return Scaffold(
        key: _scaffoldKey,
        appBar: widget.appBar,
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(child: Text('Navigation')),
              ...widget.destinations.asMap().entries.map((entry) {
                final index = entry.key;
                final destination = entry.value;
                return ListTile(
                  leading: destination.icon,
                  title: Text(destination.label),
                  selected: widget.selectedIndex == index,
                  onTap: () {
                    widget.onDestinationSelected(index);
                    Navigator.pop(context); // Close drawer
                  },
                );
              }).toList(),
            ],
          ),
        ),
        body: widget.contentBuilder(context),
        backgroundColor: widget.backgroundColor,
      );
    }

    // Tablet/Desktop: Use persistent rail
    return Scaffold(
      key: _scaffoldKey,
      appBar: widget.appBar,
      body: Row(
        children: [
          NavigationRail(
            destinations: widget.destinations
                .map((d) => NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon ?? d.icon,
                  label: Text(d.label),
                ))
                .toList(),
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            labelType: ScreenSize.isTablet(context)
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.all,
            backgroundColor: widget.backgroundColor,
          ),
          Expanded(
            child: widget.contentBuilder(context),
          ),
        ],
      ),
      backgroundColor: widget.backgroundColor,
    );
  }
}

/// A responsive dialog that adjusts its width and positioning based on screen size.
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final double mobileWidth;
  final double tabletWidth;
  final double desktopWidth;
  final EdgeInsets? padding;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.mobileWidth = 0.9, // 90% of screen width
    this.tabletWidth = 0.7, // 70% of screen width
    this.desktopWidth = 500, // Fixed 500 dp on desktop
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = ScreenSize.getWidth(context);
    
    late double dialogWidth;
    if (ScreenSize.isMobile(context)) {
      dialogWidth = screenWidth * mobileWidth;
    } else if (ScreenSize.isTablet(context)) {
      dialogWidth = screenWidth * tabletWidth;
    } else {
      dialogWidth = desktopWidth;
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.all(ResponsiveSpacing.getHorizontalPadding(context)),
          child: child,
        ),
      ),
    );
  }
}

/// A responsive bottom sheet that adjusts its height based on screen size.
class ResponsiveBottomSheet extends StatelessWidget {
  final Widget child;
  final double mobileInitialSize;
  final double tabletInitialSize;
  final bool isScrollControlled;

  const ResponsiveBottomSheet({
    super.key,
    required this.child,
    this.mobileInitialSize = 0.75,
    this.tabletInitialSize = 0.6,
    this.isScrollControlled = true,
  });

  @override
  Widget build(BuildContext context) {
    final initialSize = ScreenSize.isMobile(context)
        ? mobileInitialSize
        : tabletInitialSize;

    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        children: [child],
      ),
    );
  }
}

/// A responsive list that shows items in a single column on mobile
/// and multiple columns on larger screens.
class ResponsiveListGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsets padding;

  const ResponsiveListGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveColumns.getGridColumns(context);
    
    if (columns == 1) {
      return SingleChildScrollView(
        padding: padding,
        child: Column(
          spacing: spacing,
          children: children,
        ),
      );
    }

    // Multi-column layout
    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      padding: padding,
      children: children,
    );
  }
}

/// Helper widget for showing/hiding widgets based on screen size
class ResponsiveVisibility extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? child; // Fallback for all sizes

  const ResponsiveVisibility({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return mobile ?? child ?? const SizedBox.shrink();
    } else if (ScreenSize.isTablet(context)) {
      return tablet ?? child ?? const SizedBox.shrink();
    } else {
      return desktop ?? child ?? const SizedBox.shrink();
    }
  }
}

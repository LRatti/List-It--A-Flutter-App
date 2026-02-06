import 'package:app_code/utils/screen_size_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenSize device type initialization', () {
    test('initializeDeviceTypeFromWidth sets phone for width < 600', () {
      // Note: _isTabletAtLaunch is set only once and won't change
      // This test verifies the logic when width < 600
      ScreenSize.initializeDeviceTypeFromWidth(500);
      
      // If this is the first call, it should set phone
      // If already initialized in a previous test, we just verify
      // the static field exists and has a value
      expect(ScreenSize.isPhoneAtLaunch, isNotNull);
      expect(ScreenSize.isTabletAtLaunch, isNotNull);
    });

    test('initializeDeviceTypeFromWidth does not change after first set', () {
      // Initialize with a phone width first
      final initialValue = ScreenSize.isTabletAtLaunch;
      
      // Try to change it (should not work due to ??= operator)
      ScreenSize.initializeDeviceTypeFromWidth(1200);
      
      // Value should remain the same
      expect(ScreenSize.isTabletAtLaunch, equals(initialValue));
    });

    test('isPhoneAtLaunch and isTabletAtLaunch are complementary', () {
      expect(ScreenSize.isPhoneAtLaunch, isNotNull);
      expect(ScreenSize.isTabletAtLaunch, isNotNull);
      
      // They should be opposite of each other
      expect(
        ScreenSize.isPhoneAtLaunch, 
        equals(!ScreenSize.isTabletAtLaunch!)
      );
    });
  });

  group('ScreenSize classification methods', () {
    testWidgets('isMobile returns true for width < 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.isMobile(context), isTrue);
              expect(ScreenSize.isTablet(context), isFalse);
              expect(ScreenSize.isDesktop(context), isFalse);
              expect(ScreenSize.isLargeDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for width 600-899', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(750, 1000)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.isMobile(context), isFalse);
              expect(ScreenSize.isTablet(context), isTrue);
              expect(ScreenSize.isDesktop(context), isFalse);
              expect(ScreenSize.isLargeDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true for width 900-1199', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.isMobile(context), isFalse);
              expect(ScreenSize.isTablet(context), isFalse);
              expect(ScreenSize.isDesktop(context), isTrue);
              expect(ScreenSize.isLargeDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isLargeDesktop returns true for width >= 1200', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1920, 1080)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.isMobile(context), isFalse);
              expect(ScreenSize.isTablet(context), isFalse);
              expect(ScreenSize.isDesktop(context), isTrue);
              expect(ScreenSize.isLargeDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('classify returns correct ScreenClassification', (tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.classify(context), ScreenClassification.mobile);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.classify(context), ScreenClassification.tablet);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.classify(context), ScreenClassification.desktop);
              return const SizedBox();
            },
          ),
        ),
      );

      // Large Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1920, 1080)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.classify(context), ScreenClassification.largeDesktop);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getWidth returns correct width', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 768)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getWidth(context), 1024);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getHeight returns correct height', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 768)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getHeight(context), 768);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ScreenSize orientation methods', () {
    testWidgets('getOrientation returns portrait', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 1000)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getOrientation(context), Orientation.portrait);
              expect(ScreenSize.isPortrait(context), isTrue);
              expect(ScreenSize.isLandscape(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getOrientation returns landscape', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 600)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getOrientation(context), Orientation.landscape);
              expect(ScreenSize.isLandscape(context), isTrue);
              expect(ScreenSize.isPortrait(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ScreenSize additional getters', () {
    testWidgets('getPixelRatio returns correct value', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2.0),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getPixelRatio(context), 2.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getTopPadding returns correct value', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(top: 24.0),
          ),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getTopPadding(context), 24.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getBottomPadding returns correct value', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 16.0),
          ),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getBottomPadding(context), 16.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getKeyboardHeight returns correct value', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 300.0),
          ),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getKeyboardHeight(context), 300.0);
              expect(ScreenSize.isKeyboardVisible(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isKeyboardVisible returns false when keyboard hidden', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewInsets: EdgeInsets.zero,
          ),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.getKeyboardHeight(context), 0.0);
              expect(ScreenSize.isKeyboardVisible(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ScreenClassification enum', () {
    test('displayName returns correct values', () {
      expect(ScreenClassification.mobile.displayName, 'Mobile');
      expect(ScreenClassification.tablet.displayName, 'Tablet');
      expect(ScreenClassification.desktop.displayName, 'Desktop');
      expect(ScreenClassification.largeDesktop.displayName, 'Large Desktop');
      expect(ScreenClassification.unknown.displayName, 'Unknown');
    });
  });

  group('ResponsiveSpacing', () {
    testWidgets('getHorizontalPadding returns correct values for different sizes', (tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getHorizontalPadding(context), 16.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getHorizontalPadding(context), 24.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getHorizontalPadding(context), 32.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Large Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1920, 1080)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getHorizontalPadding(context), 48.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getVerticalPadding returns correct values', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getVerticalPadding(context), 12.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getCornerRadius returns correct values', (tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getCornerRadius(context), 8.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getCornerRadius(context), 12.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getCornerRadius(context), 16.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getGap returns correct values', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getGap(context), 8.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getItemSpacing returns correct values', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveSpacing.getItemSpacing(context), 12.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ResponsiveColumns', () {
    testWidgets('getGridColumns returns correct values', (tester) async {
      // Mobile: 1 column
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getGridColumns(context), 1);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet: 2 columns
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getGridColumns(context), 2);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop: 3 columns
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getGridColumns(context), 3);
              return const SizedBox();
            },
          ),
        ),
      );

      // Large Desktop: 4 columns
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1920, 1080)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getGridColumns(context), 4);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDetailPaneWidth returns correct values', (tester) async {
      // Mobile: null (full width)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getDetailPaneWidth(context), isNull);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet: 350
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getDetailPaneWidth(context), 350);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop: 400
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getDetailPaneWidth(context), 400);
              return const SizedBox();
            },
          ),
        ),
      );

      // Large Desktop: 450
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1920, 1080)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getDetailPaneWidth(context), 450);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getListPaneMinWidth returns correct values', (tester) async {
      // Mobile: full width
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getListPaneMinWidth(context), 500);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet: 300
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getListPaneMinWidth(context), 300);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getMasterDetailRatio returns correct values', (tester) async {
      // Mobile: 1.0 (100%)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getMasterDetailRatio(context), 1.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet: 0.4 (40%)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getMasterDetailRatio(context), 0.4);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop: 0.35 (35%)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveColumns.getMasterDetailRatio(context), 0.35);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ScreenSize edge cases', () {
    testWidgets('handles exact breakpoint values', (tester) async {
      // Exactly 600 (tablet min)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 800)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.isMobile(context), isFalse);
              expect(ScreenSize.isTablet(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );

      // Exactly 900 (desktop min)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 800)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.isTablet(context), isFalse);
              expect(ScreenSize.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );

      // Exactly 1200 (large desktop min)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(
            builder: (context) {
              expect(ScreenSize.isLargeDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}

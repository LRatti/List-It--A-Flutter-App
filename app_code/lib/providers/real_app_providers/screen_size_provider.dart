import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/utils/screen_size_helper.dart';
import 'package:flutter_riverpod/legacy.dart';

/// StateNotifier for reactive screen size changes.
/// 
/// This notifier tracks the current screen classification and notifies
/// listeners whenever the screen size or orientation changes.
/// This allows responsive widgets to rebuild automatically without needing
/// to manually check MediaQuery in their build methods.
/// 
/// NOTE: Initialized with 'unknown' to guarantee the first actual measurement
/// triggers a state change notification, even if subsequent classification
/// matches the default. This ensures responsive widgets rebuild on cold start.
class ScreenSizeNotifier extends StateNotifier<ScreenClassification> {
  ScreenSizeNotifier() : super(ScreenClassification.unknown);

  /// Update the screen size classification and notify listeners
  void updateScreenSize(ScreenClassification newClassification) {
    if (state != newClassification) {
      state = newClassification;
    }
  }

  /// Get current screen classification
  ScreenClassification getCurrentClassification() => state;
}

/// Riverpod provider for reactive screen size changes.
/// 
/// Widgets can watch this provider to automatically rebuild when the screen
/// size changes (orientation, rotation, tablet/mobile transitions, etc.).
final screenSizeProvider = StateNotifierProvider<ScreenSizeNotifier, ScreenClassification>(
  (ref) => ScreenSizeNotifier(),
);

/// Convenience provider to get the screen size directly from BuildContext
/// without needing MediaQuery. This is useful in Riverpod consumers.
///
/// Returns the current screen classification based on observable screen size.
final screenClassificationProvider = Provider<ScreenClassification>((ref) {
  return ref.watch(screenSizeProvider);
});

/// Check if currently in mobile view
final isMobileProvider = Provider<bool>((ref) {
  final classification = ref.watch(screenSizeProvider);
  return classification == ScreenClassification.mobile;
});

/// Check if currently in tablet view
final isTabletProvider = Provider<bool>((ref) {
  final classification = ref.watch(screenSizeProvider);
  return classification == ScreenClassification.tablet;
});

/// Check if currently in desktop view
final isDesktopProvider = Provider<bool>((ref) {
  final classification = ref.watch(screenSizeProvider);
  return classification == ScreenClassification.desktop ||
      classification == ScreenClassification.largeDesktop;
});

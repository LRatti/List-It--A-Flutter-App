import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/screens/settings/settings_screen_mobile.dart';
import 'package:app_code/providers/real_app_providers/app-style/theme_provider.dart';
import 'package:app_code/providers/real_app_providers/app-style/font_size_provider.dart';

class _FakeThemeNotifier extends ThemeNotifier {
  _FakeThemeNotifier(this.initial);
  final ThemeMode initial;

  @override
  Future<ThemeMode> build() async => initial;

  ThemeMode? lastSet;
  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    lastSet = mode;
    state = AsyncValue.data(mode);
  }
}

class _FakeFontSizeNotifier extends FontSizeNotifier {
  _FakeFontSizeNotifier(this.initial);
  final double initial;

  double? lastSet;

  @override
  Future<double> build() async => initial;

  @override
  Future<void> setFontSize(double multiplier) async {
    lastSet = multiplier;
    state = AsyncValue.data(multiplier);
  }
}

Future<ProviderContainer> _pumpSettings(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
  double fontSize = 1.0,
}) async {
  final themeNotifier = _FakeThemeNotifier(theme);
  final fontSizeNotifier = _FakeFontSizeNotifier(fontSize);

  final container = ProviderContainer(
    overrides: [
      themeProvider.overrideWith(() => themeNotifier),
      fontSizeProvider.overrideWith(() => fontSizeNotifier),
    ],
  );

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: const SettingsScreenMobile(),
        themeMode: theme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows switches and slider with initial values', (tester) async {
    await _pumpSettings(tester, theme: ThemeMode.dark, fontSize: 1.2);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);

    final switchFinder = find.byType(Switch).at(1); // second switch is Dark Mode
    final darkSwitch = tester.widget<Switch>(switchFinder);
    expect(darkSwitch.value, isTrue);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, closeTo(1.2, 0.001));
    expect(find.text('120%'), findsOneWidget);
  });

  testWidgets('toggling dark mode calls notifier', (tester) async {
    final container = await _pumpSettings(tester, theme: ThemeMode.light);
    final notifier = container.read(themeProvider.notifier) as _FakeThemeNotifier;

    final switchFinder = find.byType(Switch).at(1);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(notifier.lastSet, ThemeMode.dark);
  });

  testWidgets('dragging font size slider updates label and calls notifier on end', (tester) async {
    final container = await _pumpSettings(tester, fontSize: 1.0);
    final notifier = container.read(fontSizeProvider.notifier) as _FakeFontSizeNotifier;

    final sliderFinder = find.byType(Slider);
    
    // A safer way to "set" the value in a test if drag is too unpredictable:
    // We simulate the sequence of events manually
    final slider = tester.widget<Slider>(sliderFinder);
    slider.onChanged!(1.3); // Simulate moving
    await tester.pump();
    expect(find.textContaining('130%'), findsOneWidget);

    slider.onChangeEnd!(1.3); // Simulate releasing the finger
    await tester.pumpAndSettle();
    
    expect(notifier.lastSet, closeTo(1.3, 0.01));
  });
}

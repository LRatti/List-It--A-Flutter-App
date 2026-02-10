import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/screens/settings/settings_screen.dart';
import 'package:app_code/providers/real_app_providers/app-style/theme_provider.dart';
import 'package:app_code/providers/real_app_providers/app-style/font_size_provider.dart';
import 'package:app_code/providers/real_app_providers/locale_provider.dart';

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

class _FakeLocaleNotifier extends LocaleNotifier {
  _FakeLocaleNotifier(this.initial);

  final Locale initial;
  Locale? lastSet;

  @override
  Locale build() => initial;

  @override
  Future<void> setLocale(Locale newLocale) async {
    lastSet = newLocale;
    state = newLocale;
  }
}

Future<ProviderContainer> _pumpSettings(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
  double fontSize = 1.0,
  Locale locale = const Locale('en'),
}) async {
  final themeNotifier = _FakeThemeNotifier(theme);
  final fontSizeNotifier = _FakeFontSizeNotifier(fontSize);
  final localeNotifier = _FakeLocaleNotifier(locale);

  final container = ProviderContainer(
    overrides: [
      themeProvider.overrideWith(() => themeNotifier),
      fontSizeProvider.overrideWith(() => fontSizeNotifier),
      localeProvider.overrideWith(() => localeNotifier),
    ],
  );

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
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
    final l10n = AppLocalizations.of(tester.element(find.byType(SettingsScreenMobile)))!;

    expect(find.text(l10n.settingsTitle), findsOneWidget);
    expect(find.text(l10n.darkModeLabel), findsOneWidget);

    final darkTile = find.widgetWithText(ListTile, l10n.darkModeLabel);
    final darkSwitchFinder = find.descendant(
      of: darkTile,
      matching: find.byType(Switch),
    );
    final darkSwitch = tester.widget<Switch>(darkSwitchFinder);
    expect(darkSwitch.value, isTrue);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, closeTo(1.2, 0.001));
    expect(find.text('120%'), findsOneWidget);
  });

  testWidgets('toggling dark mode calls notifier', (tester) async {
    final container = await _pumpSettings(tester, theme: ThemeMode.light);
    final notifier = container.read(themeProvider.notifier) as _FakeThemeNotifier;
    final l10n = AppLocalizations.of(tester.element(find.byType(SettingsScreenMobile)))!;

    final darkTile = find.widgetWithText(ListTile, l10n.darkModeLabel);
    final darkSwitchFinder = find.descendant(
      of: darkTile,
      matching: find.byType(Switch),
    );
    await tester.tap(darkSwitchFinder);
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

  testWidgets('shows preview and color palette sections', (tester) async {
    final themeNotifier = _FakeThemeNotifier(ThemeMode.light);
    final fontSizeNotifier = _FakeFontSizeNotifier(1.0);
    final localeNotifier = _FakeLocaleNotifier(const Locale('en'));

    final container = ProviderContainer(
      overrides: [
        themeProvider.overrideWith(() => themeNotifier),
        fontSizeProvider.overrideWith(() => fontSizeNotifier),
        localeProvider.overrideWith(() => localeNotifier),
      ],
    );

    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: SettingsScreenTablet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(SettingsScreenTablet)))!;

    expect(find.text(l10n.textPreviewTitle), findsOneWidget);
    expect(find.text(l10n.colorPaletteTitle), findsOneWidget);
    expect(find.text(l10n.colorSwatchPrimary), findsOneWidget);
    expect(find.text(l10n.colorSwatchSecondary), findsOneWidget);
  });

  testWidgets('changing language calls notifier', (tester) async {
    final container = await _pumpSettings(tester, locale: const Locale('en'));
    final notifier = container.read(localeProvider.notifier) as _FakeLocaleNotifier;
    final l10n = AppLocalizations.of(tester.element(find.byType(SettingsScreenMobile)))!;

    final languageTile = find.widgetWithText(ListTile, l10n.languageLabel);
    final dropdown = find.descendant(
      of: languageTile,
      matching: find.byType(DropdownButton<Locale>),
    );

    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.languageItalianLabel).last);
    await tester.pumpAndSettle();

    expect(notifier.lastSet, const Locale('it'));
  });
}

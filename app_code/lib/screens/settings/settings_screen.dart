import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/providers/real_app_providers/app-style/theme_provider.dart';
import 'package:app_code/providers/real_app_providers/app-style/font_size_provider.dart';
import 'package:app_code/providers/real_app_providers/locale_provider.dart';

/// Mobile settings screen: single column vertical layout.
class SettingsScreenMobile extends ConsumerStatefulWidget {
  const SettingsScreenMobile({super.key});

  @override
  ConsumerState<SettingsScreenMobile> createState() =>
      _SettingsScreenMobileViewState();
}

/// Tablet settings screen: two-column layout with preview panel.
class SettingsScreenTablet extends ConsumerStatefulWidget {
  const SettingsScreenTablet({super.key});

  @override
  ConsumerState<SettingsScreenTablet> createState() =>
      _SettingsScreenTabletViewState();
}

/// Base state class for settings screen, containing shared logic 
/// and UI components.
abstract class _SettingsScreenBaseState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  late double _tempFontSize;

  @override
  void initState() {
    super.initState();
    final fontSizeAsync = ref.read(fontSizeProvider);
    _tempFontSize = fontSizeAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 1.0,
    );

    ref.listenManual(fontSizeProvider, (previous, next) {
      next.whenData((value) {
        if (_tempFontSize != value) {
          setState(() {
            _tempFontSize = value;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeValueProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: true,
      ),
      body: buildLayout(context, themeMode, colorScheme, textTheme, l10n),
    );
  }

  Widget buildLayout(
    BuildContext context,
    ThemeMode themeMode,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  );

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeMode themeMode,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Divider(),
        _buildThemeSection(themeMode, colorScheme, l10n),
        const Divider(),
        _buildFontSizeSection(colorScheme, textTheme, l10n),
        const Divider(),
        _buildLanguageSection(l10n),
        const Divider(),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(
    BuildContext context,
    ThemeMode themeMode,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings panel (left)
        Flexible(
          flex: 50,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Divider(height: 32),
              _buildThemeSection(themeMode, colorScheme, l10n),
              const Divider(height: 32),
              _buildFontSizeSection(colorScheme, textTheme, l10n, compact: true),
              const Divider(height: 32),
              _buildLanguageSection(l10n),
              const Divider(height: 32),
            ],
          ),
        ),
        // Preview panel (right)
        Flexible(
          flex: 50,
          child: Container(
            color: colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: [
                  _buildPreviewSection(colorScheme, textTheme, l10n),
                  const Divider(),
                  _buildColorPreviewSection(colorScheme, l10n),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection(
    ThemeMode themeMode,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return ListTile(
      title: Text(l10n.darkModeLabel),
      trailing: Switch(
        value: themeMode == ThemeMode.dark,
        onChanged: (value) {
          ref.read(themeProvider.notifier).setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
        },
      ),
    );
  }

  Widget _buildFontSizeSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n, {
    bool compact = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.fontSizeLabel,
                  style: textTheme.titleMedium,
                ),
                Text(
                  '${(_tempFontSize * 100).toStringAsFixed(0)}%',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _tempFontSize,
            min: FontSizeNotifier.fontSizeRange.min,
            max: FontSizeNotifier.fontSizeRange.max,
            divisions: 6,
            label: '${(_tempFontSize * 100).toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() {
                _tempFontSize = value;
              });
            },
            onChangeEnd: (value) {
              ref.read(fontSizeProvider.notifier).setFontSize(value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.fontSizeSmallLabel, style: textTheme.labelSmall),
                Text(l10n.fontSizeLargeLabel, style: textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          l10n.textPreviewTitle,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                l10n.textPreviewDisplayLarge,
                style: textTheme.displayLarge,
              ),
              Text(
                l10n.textPreviewHeadlineMedium,
                style: textTheme.headlineMedium,
              ),
              Text(
                l10n.textPreviewTitleMedium,
                style: textTheme.titleMedium,
              ),
              Text(
                l10n.textPreviewBodyMedium,
                style: textTheme.bodyMedium,
              ),
              Text(
                l10n.textPreviewBodySmall,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorPreviewSection(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          l10n.colorPaletteTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildColorSwatch(l10n.colorSwatchPrimary, colorScheme.primary),
        _buildColorSwatch(l10n.colorSwatchSecondary, colorScheme.secondary),
        _buildColorSwatch(l10n.colorSwatchTertiary, colorScheme.tertiary),
        _buildColorSwatch(l10n.colorSwatchError, colorScheme.error),
        _buildColorSwatch(l10n.colorSwatchSurface, colorScheme.surface),
      ],
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Row(
      spacing: 12,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildLanguageSection(AppLocalizations l10n) {
    // Watch the state directly through Riverpod
    final currentLocale = ref.watch(localeProvider);

    return ListTile(
      title: Text(l10n.languageLabel),
      trailing: DropdownButton<Locale>(
        value: currentLocale,
        onChanged: (locale) {
          if (locale == null) return;
          // Update state through the notifier
          ref.read(localeProvider.notifier).setLocale(locale);
        },
        items: [
          DropdownMenuItem(
            value: const Locale('en'),
            child: Text(l10n.languageEnglishLabel),
          ),
          DropdownMenuItem(
            value: const Locale('it'),
            child: Text(l10n.languageItalianLabel),
          ),
        ],
      ),
    );
  }
}

class _SettingsScreenMobileViewState
  extends _SettingsScreenBaseState<SettingsScreenMobile> {
  @override
  Widget buildLayout(
    BuildContext context,
    ThemeMode themeMode,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return _buildMobileLayout(context, themeMode, colorScheme, textTheme, l10n);
  }
}

class _SettingsScreenTabletViewState
  extends _SettingsScreenBaseState<SettingsScreenTablet> {
  @override
  Widget buildLayout(
    BuildContext context,
    ThemeMode themeMode,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return _buildTabletDesktopLayout(context, themeMode, colorScheme, textTheme, l10n);
  }
}

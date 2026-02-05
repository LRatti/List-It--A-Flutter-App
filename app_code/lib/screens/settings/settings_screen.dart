import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/app-style/theme_provider.dart';
import 'package:app_code/providers/real_app_providers/app-style/font_size_provider.dart';
import 'package:app_code/utils/screen_size_helper.dart';

/// Responsive settings screen with adaptive layout.
/// 
/// Mobile: Single column vertical layout
/// Tablet+: Two-column layout with settings on left, preview on right
class SettingsScreenResponsive extends ConsumerStatefulWidget {
  const SettingsScreenResponsive({super.key});

  @override
  ConsumerState<SettingsScreenResponsive> createState() =>
      _SettingsScreenResponsiveState();
}

class _SettingsScreenResponsiveState extends ConsumerState<SettingsScreenResponsive> {
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
    final isMobile = ScreenSize.isMobile(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: isMobile
          ? _buildMobileLayout(context, themeMode, colorScheme, textTheme)
          : _buildTabletDesktopLayout(context, themeMode, colorScheme, textTheme),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeMode themeMode,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNotificationsSection(),
        const Divider(),
        _buildThemeSection(themeMode, colorScheme),
        const Divider(),
        _buildFontSizeSection(colorScheme, textTheme),
        const Divider(),
        _buildAboutSection(),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(
    BuildContext context,
    ThemeMode themeMode,
    ColorScheme colorScheme,
    TextTheme textTheme,
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
              _buildNotificationsSection(),
              const Divider(height: 32),
              _buildThemeSection(themeMode, colorScheme),
              const Divider(height: 32),
              _buildFontSizeSection(colorScheme, textTheme, compact: true),
              const Divider(height: 32),
              _buildAboutSection(),
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
                  _buildPreviewSection(colorScheme, textTheme),
                  const Divider(),
                  _buildColorPreviewSection(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return ListTile(
      title: const Text('Notifications'),
      trailing: Switch(
        value: true,
        onChanged: (value) {},
      ),
    );
  }

  Widget _buildThemeSection(ThemeMode themeMode, ColorScheme colorScheme) {
    return ListTile(
      title: const Text('Dark Mode'),
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
    TextTheme textTheme, {
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
                  'Font Size',
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
                Text('Small', style: textTheme.labelSmall),
                Text('Large', style: textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Text Preview',
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
                'Display Large',
                style: textTheme.displayLarge,
              ),
              Text(
                'Headline Medium',
                style: textTheme.headlineMedium,
              ),
              Text(
                'Title Medium - This is how your body text will look with the selected font size.',
                style: textTheme.titleMedium,
              ),
              Text(
                'Body Medium - This is standard body text for reading content and descriptions.',
                style: textTheme.bodyMedium,
              ),
              Text(
                'Body Small - Smaller text for less important information.',
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

  Widget _buildColorPreviewSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Color Palette',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildColorSwatch('Primary', colorScheme.primary),
        _buildColorSwatch('Secondary', colorScheme.secondary),
        _buildColorSwatch('Tertiary', colorScheme.tertiary),
        _buildColorSwatch('Error', colorScheme.error),
        _buildColorSwatch('Surface', colorScheme.surface),
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

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('App Version'),
          subtitle: const Text('1.0.0'),
          trailing: const Icon(Icons.info_outline),
        ),
        ListTile(
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {},
        ),
        ListTile(
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {},
        ),
      ],
    );
  }
}

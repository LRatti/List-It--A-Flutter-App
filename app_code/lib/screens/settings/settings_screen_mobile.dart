import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/app-style/theme_provider.dart';
import 'package:app_code/providers/real_app_providers/app-style/font_size_provider.dart';

class SettingsScreenMobile extends ConsumerStatefulWidget {
  const SettingsScreenMobile({super.key});

  @override
  ConsumerState<SettingsScreenMobile> createState() =>
      _SettingsScreenMobileState();
}

class _SettingsScreenMobileState extends ConsumerState<SettingsScreenMobile> {
  late double _tempFontSize;

  @override
  void initState() {
    super.initState();
    // Initialize with current font size from provider
    final fontSizeAsync = ref.read(fontSizeProvider);
    _tempFontSize = fontSizeAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 1.0,
    );

    // Listen for external font size changes (e.g., from other screens)
    // This ensures we sync if changed elsewhere, but doesn't rebuild during drag
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
    // Only watch theme mode via value provider (avoid async + lag during slider drag)
    final themeMode = ref.watch(themeModeValueProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Setting
          ListTile(
            title: const Text('Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          const Divider(),

          // Dark Mode Setting
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ),
          const Divider(),

          // Font Size Setting
          Padding(
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
                  divisions: 6, // 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4
                  label: '${(_tempFontSize * 100).toStringAsFixed(0)}%',
                  // Update UI reactively while dragging
                  onChanged: (value) {
                    setState(() {
                      _tempFontSize = value;
                    });
                  },
                  // Persist to storage only when drag ends (efficient)
                  onChangeEnd: (value) {
                    ref.read(fontSizeProvider.notifier).setFontSize(value);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Small',
                        style: textTheme.labelSmall,
                      ),
                      Text(
                        'Large',
                        style: textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is how your text will look',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Smaller body text example',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // About Setting
          ListTile(
            title: const Text('About'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

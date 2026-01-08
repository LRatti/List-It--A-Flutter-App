import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/text_scale_provider.dart';

class SettingsScreenMobile extends ConsumerWidget {
  const SettingsScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale = ref.watch(textScaleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0 * textScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0 * textScale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Text Size', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 16.0 * textScale),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: textScale,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label: '${(textScale * 100).toStringAsFixed(0)}%',
                            onChanged: (value) {
                              ref.read(textScaleProvider.notifier).setTextScale(value);
                            },
                          ),
                        ),
                        SizedBox(width: 12.0 * textScale),
                        Text('${(textScale * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    SizedBox(height: 12.0 * textScale),
                    Text('Adjust text size for better readability',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0 * textScale),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(textScaleProvider.notifier).resetTextScale();
                },
                child: const Text('Reset to Default'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/text_scale_provider.dart';
import 'package:app_code/screens/settings/settings_screen_mobile.dart';

class TopBarWithNavBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopBarWithNavBar({super.key});

  // Provide a generous height to avoid overflow at large text scales.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale = ref.watch(textScaleProvider);
    final infoBarHeight = (40.0 * textScale).clamp(32.0, 72.0);

    return AppBar(
      title: const Text("My Shopping App"),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreenMobile(),
              ),
            );
          },
          icon: const Icon(Icons.settings),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(infoBarHeight),
        child: Container(
          width: double.infinity,
          color: Colors.grey[200],
          padding: EdgeInsets.symmetric(
            horizontal: 12.0 * textScale,
            vertical: 8.0 * textScale,
          ),
          child: Row(
            children: const [
              Icon(Icons.location_on_outlined, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Nearest supermarket: internet not available",
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

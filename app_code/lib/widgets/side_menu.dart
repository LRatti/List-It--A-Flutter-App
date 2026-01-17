import 'package:flutter/material.dart';
import 'package:app_code/screens/settings/settings_screen_mobile.dart';
import 'package:app_code/screens/trash/trash_screen_mobile.dart';
import 'package:app_code/screens/profile/settings_screen.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const SideMenu({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      color: colorScheme.surface, // Main background matches theme
      child: Column(
        children: [
          Container(
            color: colorScheme.primary, // Top bar background
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onPrimary),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                ListTile(
                  leading: Icon(Icons.person, color: colorScheme.primary),
                  title: Text(
                    'Profile',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () {
                    onClose();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: colorScheme.primary),
                  title: Text(
                    'Settings',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () {
                    onClose();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreenMobile(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete_outlined, color: colorScheme.error),
                  title: Text(
                    'Trash',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () {
                    onClose();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrashScreenMobile(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

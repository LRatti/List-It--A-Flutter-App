import 'package:flutter/material.dart';

class SettingsScreenMobile extends StatelessWidget {
  const SettingsScreenMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: false,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

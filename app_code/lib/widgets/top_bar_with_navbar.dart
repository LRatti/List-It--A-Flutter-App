import 'package:flutter/material.dart';

class TopBarWithNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBarWithNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: const Text('My Shopping App'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.person),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.all(12),
          child: const Text(
            'Nearest supermarket: internet not available',
            style: TextStyle(fontSize: 16),
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize {
    // Minimum guaranteed height.
    // If text scale increases, Flutter will expand the layout automatically.
    return const Size.fromHeight(kToolbarHeight + 56);
  }
}

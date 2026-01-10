import 'package:flutter/material.dart';

class TopBarWithNavBar extends StatelessWidget {
  final bool isMenuOpen;
  final VoidCallback onMenuToggle;

  const TopBarWithNavBar({
    super.key,
    required this.isMenuOpen,
    required this.onMenuToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: const Text('My Shopping App'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onMenuToggle,
          ),
          actions: const [],
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
}

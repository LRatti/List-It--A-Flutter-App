import 'package:flutter/material.dart';

SnackBar buildAppSnackBar({
  required String message,
  bool isError = false,
  VoidCallback? onTap,
  Duration duration = const Duration(seconds: 5),
}) {
  final backgroundColor = isError ? Colors.orange : Colors.green;
  final icon = isError ? Icons.warning_amber : Icons.check_circle;

  final content = Row(
    children: [
      Icon(icon, color: Colors.white),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (onTap != null)
        const Icon(Icons.touch_app, size: 18, color: Colors.white70),
    ],
  );

  return SnackBar(
    content: onTap != null ? GestureDetector(onTap: onTap, child: content) : content,
    backgroundColor: backgroundColor,
    duration: duration,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
  );
}

import 'package:flutter/material.dart';

SnackBar buildAppSnackBar({
  required String message,
  bool isError = false,
  VoidCallback? onTap,
  Duration duration = const Duration(seconds: 5),
  BuildContext? context,
}) {
  final colorScheme = context != null ? Theme.of(context).colorScheme : null;

  final backgroundColor = isError
      ? colorScheme?.errorContainer ?? Colors.red[600]
      : colorScheme?.secondaryContainer ?? Colors.green[600];

  final iconColor = isError
      ? colorScheme?.onErrorContainer ?? Colors.white
      : colorScheme?.onSecondaryContainer ?? Colors.white;

  final icon = isError ? Icons.warning_amber : Icons.check_circle;

  // Create a slightly transparent version of iconColor without using withOpacity
  final touchIconColor = iconColor.withAlpha(179); // ~70% opacity

  final content = Row(
    children: [
      Icon(icon, color: iconColor),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          message,
          style: TextStyle(color: iconColor),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (onTap != null)
        Icon(Icons.touch_app, size: 18, color: touchIconColor),
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

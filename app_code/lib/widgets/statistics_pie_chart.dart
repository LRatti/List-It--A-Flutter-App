import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:app_code/l10n/app_localizations.dart';

/// A donut-style pie chart widget that displays category spending data
/// Shows total amount in the center with colored segments for each category
class StatisticsPieChart extends StatelessWidget {
  const StatisticsPieChart({
    super.key,
    required this.entries,
    required this.total, required Null Function(dynamic categoryName) onCategoryTap,
  });

  /// List of category names and their spending amounts
  final List<MapEntry<String, double>> entries;
  
  /// Total spending across all categories
  final double total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return CustomPaint(
      painter: PieChartPainter(
        entries: entries,
        total: total,
        backgroundColor: colorScheme.surface, // donut hole background matches theme
        colorScheme: colorScheme,
      ),
      child: Center(
        child: Text(
          '${l10n.totalLabel}\nEUR ${total.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface, // text color adapts to light/dark mode
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a donut-style pie chart
/// Each category is represented by a colored arc segment
class PieChartPainter extends CustomPainter {
  PieChartPainter({
    required this.entries,
    required this.total,
    required this.backgroundColor,
    required this.colorScheme,
  });

  final List<MapEntry<String, double>> entries;
  final double total;
  final Color backgroundColor;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final radius = math.min(size.width, size.height) / 2;
    final center = rect.center;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * math.pi;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _colorForIndex(i);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );

      startAngle += sweep;
    }

    // Draw donut hole using theme surface color
    final holePaint = Paint()
      ..color = backgroundColor
      ..blendMode = BlendMode.srcOver;
    canvas.drawCircle(center, radius * 0.45, holePaint);
  }

  /// Returns a color for each index using theme-aware colors
  Color _colorForIndex(int index) {
    // Use a set of semantic colors for light/dark mode instead of fixed primaries
    final themeColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary ?? colorScheme.primaryContainer,
      colorScheme.error,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer ?? colorScheme.secondaryContainer,
    ];
    return themeColors[index % themeColors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

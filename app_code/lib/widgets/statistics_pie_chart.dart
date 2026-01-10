import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A donut-style pie chart widget that displays category spending data
/// Shows total amount in the center with colored segments for each category
class StatisticsPieChart extends StatelessWidget {
  const StatisticsPieChart({super.key, required this.entries, required this.total});

  /// List of category names and their spending amounts
  final List<MapEntry<String, double>> entries;
  
  /// Total spending across all categories
  final double total;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PieChartPainter(entries: entries, total: total),
      child: Center(
        child: Text(
          'Total\nEUR ${total.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Custom painter that draws a donut-style pie chart
/// Each category is represented by a colored arc segment
class PieChartPainter extends CustomPainter {
  PieChartPainter({required this.entries, required this.total});

  /// List of category names and their spending amounts
  final List<MapEntry<String, double>> entries;
  
  /// Total spending across all categories
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final radius = math.min(size.width, size.height) / 2;
    final center = rect.center;

    // Start drawing from top (12 o'clock position)
    double startAngle = -math.pi / 2;
    
    // Draw each category as an arc segment
    for (int i = 0; i < entries.length; i++) {
      // Calculate the sweep angle based on category's percentage of total
      final sweep = (entries[i].value / total) * 2 * math.pi;
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _colorForIndex(i);
      
      // Draw the arc for this category
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      
      // Move to next starting position
      startAngle += sweep;
    }

    // Draw white circle in center to create donut effect
    final holePaint = Paint()
      ..color = Colors.white
      ..blendMode = BlendMode.srcOver;
    canvas.drawCircle(center, radius * 0.45, holePaint);
  }

  /// Returns a consistent color for each category index
  /// Uses Material primary colors in a repeating cycle
  Color _colorForIndex(int index) {
    final colors = Colors.primaries;
    return colors[index % colors.length].shade400;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/utils/currency_formatter.dart';

class DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalAmount;
  final double animationProgress;
  final bool isDarkMode;

  const DonutChartPainter({
    required this.categoryTotals,
    required this.totalAmount,
    required this.animationProgress,
    this.isDarkMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.12;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // 1. Draw Empty/Background Track
    final trackPaint = Paint()
      ..color = isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (totalAmount <= 0 || categoryTotals.isEmpty) {
      _drawCenterText(
        canvas,
        center,
        '0 đ',
        'Chưa có dữ liệu',
        isDarkMode,
      );
      return;
    }

    // 2. Draw Segment Arcs
    final activeCategories = categoryTotals.entries.where((e) => e.value > 0).toList();
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (activeCategories.length == 1) {
      // If only 1 category, draw circle directly to avoid Skia 2*pi drawArc wrap-around bug
      final singleCat = activeCategories.first;
      final segmentPaint = Paint()
        ..color = singleCat.key.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (animationProgress >= 0.999) {
        canvas.drawCircle(center, radius, segmentPaint);
      } else {
        final startAngle = -math.pi / 2;
        final sweepAngle = (animationProgress * 2 * math.pi).clamp(0.001, 2 * math.pi - 0.001);
        canvas.drawArc(rect, startAngle, sweepAngle, false, segmentPaint);
      }
    } else {
      double startAngle = -math.pi / 2; // Start from 12 o'clock

      for (final entry in activeCategories) {
        final sweepFraction = (entry.value / totalAmount) * animationProgress;
        final sweepAngle = (sweepFraction * 2 * math.pi).clamp(0.0, 2 * math.pi - 0.001);

        if (sweepAngle > 0.001) {
          final segmentPaint = Paint()
            ..color = entry.key.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt;

          canvas.drawArc(
            rect,
            startAngle,
            sweepAngle,
            false,
            segmentPaint,
          );

          startAngle += sweepAngle;
        }
      }
    }

    // 3. Draw Center Summary Text
    _drawCenterText(
      canvas,
      center,
      CurrencyFormatter.formatVND(totalAmount * animationProgress),
      'Tổng chi tiêu',
      isDarkMode,
    );
  }

  void _drawCenterText(
    Canvas canvas,
    Offset center,
    String primaryText,
    String subtitle,
    bool darkMode,
  ) {
    // Primary Amount
    final titleSpan = TextSpan(
      text: primaryText,
      style: TextStyle(
        color: darkMode ? Colors.white : const Color(0xFF192A47),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 160);

    // Subtitle
    final subSpan = TextSpan(
      text: subtitle,
      style: TextStyle(
        color: darkMode ? Colors.white60 : Colors.black54,
        fontSize: 11,
      ),
    );
    final subPainter = TextPainter(
      text: subSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 160);

    final titleOffset = Offset(
      center.dx - titlePainter.width / 2,
      center.dy - (titlePainter.height + subPainter.height) / 2,
    );
    final subOffset = Offset(
      center.dx - subPainter.width / 2,
      titleOffset.dy + titlePainter.height + 2,
    );

    titlePainter.paint(canvas, titleOffset);
    subPainter.paint(canvas, subOffset);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    if (oldDelegate.animationProgress != animationProgress ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.categoryTotals.length != categoryTotals.length) {
      return true;
    }
    for (final entry in categoryTotals.entries) {
      if (oldDelegate.categoryTotals[entry.key] != entry.value) {
        return true;
      }
    }
    return false;
  }
}

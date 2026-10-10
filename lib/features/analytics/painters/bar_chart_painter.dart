import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class DailyExpensePoint {
  final String dayLabel;
  final double amount;
  final bool isToday;

  const DailyExpensePoint({
    required this.dayLabel,
    required this.amount,
    this.isToday = false,
  });
}

class BarChartPainter extends CustomPainter {
  final List<DailyExpensePoint> dailyData;
  final double maxAmount;
  final double animationProgress;
  final bool isDarkMode;

  const BarChartPainter({
    required this.dailyData,
    required this.maxAmount,
    required this.animationProgress,
    this.isDarkMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 24.0;
    const topPadding = 20.0;
    const leftPadding = 8.0;
    const rightPadding = 8.0;

    final chartHeight = size.height - bottomLabelHeight - topPadding;
    final chartWidth = size.width - leftPadding - rightPadding;

    final gridLineColor = isDarkMode ? Colors.white10 : Colors.black12;
    final labelColor = isDarkMode ? Colors.white60 : Colors.black54;

    // 1. Draw 3 Horizontal Reference Gridlines
    final gridPaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      // Value label on guideline
      if (i < 3 && maxAmount > 0) {
        final val = maxAmount * (3 - i) / 3;
        final valSpan = TextSpan(
          text: CurrencyFormatter.formatCompact(val),
          style: TextStyle(
            color: labelColor,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        );
        final tp = TextPainter(
          text: valSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(leftPadding + 2, y - tp.height - 2));
      }
    }

    if (dailyData.isEmpty) return;

    // 2. Compute Bar Sizing
    final barCount = dailyData.length;
    final barSpacing = chartWidth / barCount;
    final barWidth = math.min(barSpacing * 0.55, 28.0);

    final baselineY = topPadding + chartHeight;

    // 3. Draw Bars and Day Labels
    for (int i = 0; i < barCount; i++) {
      final point = dailyData[i];
      final centerX = leftPadding + (i + 0.5) * barSpacing;
      final barLeft = centerX - barWidth / 2;

      final normalizedAmount = maxAmount > 0 ? (point.amount / maxAmount) : 0.0;
      final currentHeight = normalizedAmount * chartHeight * animationProgress;
      final barTop = baselineY - currentHeight;

      // Subtle background capsule track for each bar slot
      final trackPaint = Paint()
        ..color = isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill;
      final trackRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, topPadding, barWidth, chartHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(trackRRect, trackPaint);

      // Bar Fill
      final barPaint = Paint()
        ..color = point.isToday
            ? AppColors.secondaryOrange
            : (point.amount > 0 ? AppColors.primaryNavy : (isDarkMode ? Colors.white12 : Colors.grey.shade300));

      if (currentHeight > 0) {
        final rrect = RRect.fromRectAndCorners(
          Rect.fromLTWH(barLeft, barTop, barWidth, currentHeight),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        );
        canvas.drawRRect(rrect, barPaint);

        // Amount label over bar
        final amountText = CurrencyFormatter.formatCompact(point.amount);
        final amountSpan = TextSpan(
          text: amountText,
          style: TextStyle(
            color: point.isToday ? AppColors.secondaryOrange : (isDarkMode ? Colors.white70 : Colors.black87),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        final atp = TextPainter(
          text: amountSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();
        atp.paint(canvas, Offset(centerX - atp.width / 2, barTop - atp.height - 3));
      }

      // Day Label below baseline
      final labelSpan = TextSpan(
        text: point.dayLabel,
        style: TextStyle(
          color: point.isToday
              ? AppColors.secondaryOrange
              : labelColor,
          fontSize: 11,
          fontWeight: point.isToday ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final ltp = TextPainter(
        text: labelSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset(centerX - ltp.width / 2, baselineY + 6));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    if (oldDelegate.animationProgress != animationProgress ||
        oldDelegate.maxAmount != maxAmount ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.dailyData.length != dailyData.length) {
      return true;
    }
    for (int i = 0; i < dailyData.length; i++) {
      if (oldDelegate.dailyData[i].amount != dailyData[i].amount ||
          oldDelegate.dailyData[i].dayLabel != dailyData[i].dayLabel ||
          oldDelegate.dailyData[i].isToday != dailyData[i].isToday) {
        return true;
      }
    }
    return false;
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../painters/donut_chart_painter.dart';

class AnimatedDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalAmount;

  const AnimatedDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool changed = oldWidget.totalAmount != widget.totalAmount ||
        oldWidget.categoryTotals.length != widget.categoryTotals.length;
    if (!changed) {
      for (final entry in widget.categoryTotals.entries) {
        if (oldWidget.categoryTotals[entry.key] != entry.value) {
          changed = true;
          break;
        }
      }
    }
    if (changed) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: DonutChartPainter(
                  categoryTotals: widget.categoryTotals,
                  totalAmount: widget.totalAmount,
                  animationProgress: _animation.value,
                  isDarkMode: isDarkMode,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    if (widget.categoryTotals.isEmpty || widget.totalAmount <= 0) {
      return const SizedBox.shrink();
    }

    final sortedEntries = widget.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: sortedEntries.map((entry) {
        final percent = (entry.value / widget.totalAmount) * 100;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: entry.key.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: entry.key.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.key.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.key.displayName}: ${percent.toStringAsFixed(0)}% (${CurrencyFormatter.formatCompact(entry.value)})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

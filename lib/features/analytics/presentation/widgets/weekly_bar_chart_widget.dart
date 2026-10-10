import 'package:flutter/material.dart';
import '../../painters/bar_chart_painter.dart';

class WeeklyBarChartWidget extends StatefulWidget {
  final List<DailyExpensePoint> dailyData;
  final double maxAmount;

  const WeeklyBarChartWidget({
    super.key,
    required this.dailyData,
    required this.maxAmount,
  });

  @override
  State<WeeklyBarChartWidget> createState() => _WeeklyBarChartWidgetState();
}

class _WeeklyBarChartWidgetState extends State<WeeklyBarChartWidget>
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
  void didUpdateWidget(covariant WeeklyBarChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool changed = oldWidget.maxAmount != widget.maxAmount ||
        oldWidget.dailyData.length != widget.dailyData.length;
    if (!changed) {
      for (int i = 0; i < widget.dailyData.length; i++) {
        if (oldWidget.dailyData[i].amount != widget.dailyData[i].amount ||
            oldWidget.dailyData[i].dayLabel != widget.dailyData[i].dayLabel) {
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: 180,
          child: CustomPaint(
            painter: BarChartPainter(
              dailyData: widget.dailyData,
              maxAmount: widget.maxAmount,
              animationProgress: _animation.value,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
    );
  }
}

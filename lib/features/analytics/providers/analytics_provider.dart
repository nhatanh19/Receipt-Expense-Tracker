import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_categories.dart';
import '../../expenses/providers/expense_provider.dart';
import '../painters/bar_chart_painter.dart';

enum BarChartMode {
  recentDays, // Các ngày chi tiêu gần nhất (đảm bảo luôn có biểu đồ trực quan)
  thisWeek,   // Tuần hiện tại (T2 - CN)
}

final barChartModeProvider = StateProvider<BarChartMode>((ref) => BarChartMode.recentDays);

class AnalyticsSummary {
  final double totalAllTime;
  final double totalThisMonth;
  final double totalThisWeek;
  final int totalCount;
  final Map<ExpenseCategory, double> categoryTotals;
  final List<DailyExpensePoint> weeklyPoints;
  final double maxDailyAmount;
  final BarChartMode mode;
  final bool hasDataInChart;
  final DateTime? latestExpenseDate;

  const AnalyticsSummary({
    required this.totalAllTime,
    required this.totalThisMonth,
    required this.totalThisWeek,
    required this.totalCount,
    required this.categoryTotals,
    required this.weeklyPoints,
    required this.maxDailyAmount,
    required this.mode,
    required this.hasDataInChart,
    this.latestExpenseDate,
  });
}

final analyticsSummaryProvider = Provider<AnalyticsSummary>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final expenses = asyncExpenses.value ?? [];
  final mode = ref.watch(barChartModeProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final thisWeekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));

  double totalAllTime = 0.0;
  double totalThisMonth = 0.0;
  double totalThisWeek = 0.0;

  final Map<ExpenseCategory, double> categoryTotals = {};
  DateTime? latestDate;

  for (final item in expenses) {
    totalAllTime += item.amount;

    if (item.timestamp.isAfter(thisMonthStart) || item.timestamp.isAtSameMomentAs(thisMonthStart)) {
      totalThisMonth += item.amount;
    }

    if (item.timestamp.isAfter(thisWeekStart) || item.timestamp.isAtSameMomentAs(thisWeekStart)) {
      totalThisWeek += item.amount;
    }

    categoryTotals[item.category] = (categoryTotals[item.category] ?? 0.0) + item.amount;

    if (latestDate == null || item.timestamp.isAfter(latestDate)) {
      latestDate = item.timestamp;
    }
  }

  final List<DailyExpensePoint> points = [];
  double maxDailyAmount = 0.0;

  if (mode == BarChartMode.thisWeek) {
    // Mode 1: Calendar week Monday -> Sunday
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    for (int i = 0; i < 7; i++) {
      final currentDay = thisWeekStart.add(Duration(days: i));
      final nextDay = currentDay.add(const Duration(days: 1));

      double daySum = 0.0;
      for (final exp in expenses) {
        if ((exp.timestamp.isAfter(currentDay) || exp.timestamp.isAtSameMomentAs(currentDay)) &&
            exp.timestamp.isBefore(nextDay)) {
          daySum += exp.amount;
        }
      }

      if (daySum > maxDailyAmount) {
        maxDailyAmount = daySum;
      }

      final isToday = todayStart.year == currentDay.year &&
          todayStart.month == currentDay.month &&
          todayStart.day == currentDay.day;

      points.add(
        DailyExpensePoint(
          dayLabel: dayLabels[i],
          amount: daySum,
          isToday: isToday,
        ),
      );
    }
  } else {
    // Mode 2: Recent Active Expense Days (up to 7 most recent dates with data)
    if (expenses.isEmpty) {
      // Default placeholder 7 days
      final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      for (int i = 0; i < 7; i++) {
        points.add(DailyExpensePoint(dayLabel: dayLabels[i], amount: 0.0));
      }
    } else {
      // Group expenses by calendar date
      final Map<DateTime, double> dateSums = {};
      for (final exp in expenses) {
        final d = DateTime(exp.timestamp.year, exp.timestamp.month, exp.timestamp.day);
        dateSums[d] = (dateSums[d] ?? 0.0) + exp.amount;
      }

      // Sort unique dates chronologically
      final sortedDates = dateSums.keys.toList()..sort((a, b) => a.compareTo(b));

      // Pick up to the last 7 dates
      final recentDates = sortedDates.length > 7
          ? sortedDates.sublist(sortedDates.length - 7)
          : sortedDates;

      for (final date in recentDates) {
        final amount = dateSums[date] ?? 0.0;
        if (amount > maxDailyAmount) maxDailyAmount = amount;

        final isToday = todayStart.year == date.year &&
            todayStart.month == date.month &&
            todayStart.day == date.day;

        // Label: d/M or d/M/yy
        final label = (date.year == now.year)
            ? '${date.day}/${date.month}'
            : '${date.day}/${date.month}/${date.year % 100}';

        points.add(
          DailyExpensePoint(
            dayLabel: label,
            amount: amount,
            isToday: isToday,
          ),
        );
      }
    }
  }

  if (maxDailyAmount == 0) maxDailyAmount = 100000;

  final hasDataInChart = points.any((p) => p.amount > 0);

  return AnalyticsSummary(
    totalAllTime: totalAllTime,
    totalThisMonth: totalThisMonth,
    totalThisWeek: totalThisWeek,
    totalCount: expenses.length,
    categoryTotals: categoryTotals,
    weeklyPoints: points,
    maxDailyAmount: maxDailyAmount,
    mode: mode,
    hasDataInChart: hasDataInChart,
    latestExpenseDate: latestDate,
  );
});

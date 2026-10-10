import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/analytics_provider.dart';
import 'widgets/animated_donut_chart.dart';
import 'widgets/weekly_bar_chart_widget.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analytics = ref.watch(analyticsSummaryProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 4 Metric Cards in 2 Rows
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Tổng chi tiêu',
                    value: CurrencyFormatter.formatVND(analytics.totalAllTime),
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF2C4570),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Tổng hóa đơn',
                    value: '${analytics.totalCount} hóa đơn',
                    icon: Icons.receipt_long,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Tháng này',
                    value: CurrencyFormatter.formatVND(analytics.totalThisMonth),
                    icon: Icons.calendar_month,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'TB / hóa đơn',
                    value: analytics.totalCount > 0
                        ? CurrencyFormatter.formatVND(analytics.totalAllTime / analytics.totalCount)
                        : '0 đ',
                    icon: Icons.analytics_outlined,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Card 1: Weekly Bar Chart (CustomPainter)
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chi tiêu theo ngày',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'CustomPainter',
                            style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analytics.mode == BarChartMode.recentDays
                          ? 'Hiển thị các ngày chi tiêu gần nhất'
                          : 'Hiển thị 7 ngày trong tuần hiện tại',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 14),

                    // Range Switcher
                    Center(
                      child: SegmentedButton<BarChartMode>(
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: BarChartMode.recentDays,
                            label: Text('Gần nhất', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.history, size: 16),
                          ),
                          ButtonSegment(
                            value: BarChartMode.thisWeek,
                            label: Text('Tuần này', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.date_range, size: 16),
                          ),
                        ],
                        selected: {analytics.mode},
                        onSelectionChanged: (newSelection) {
                          ref.read(barChartModeProvider.notifier).state = newSelection.first;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    WeeklyBarChartWidget(
                      dailyData: analytics.weeklyPoints,
                      maxAmount: analytics.maxDailyAmount,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Donut Category Chart (CustomPainter)
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Phân bổ danh mục',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Animated Canvas',
                            style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AnimatedDonutChart(
                      categoryTotals: analytics.categoryTotals,
                      totalAmount: analytics.totalAllTime,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

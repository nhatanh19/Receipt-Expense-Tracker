import 'package:flutter/material.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/expense_model.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final ExpenseItem expense;
  final VoidCallback onTap;

  const ExpenseSummaryCard({
    super.key,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: expense.category.color.withValues(alpha: 0.15),
        highlightColor: expense.category.color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Icon inside circular container indicating category
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: expense.category.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  expense.category.icon,
                  color: expense.category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // 2. Store name and date stacked vertically with CrossAxisAlignment.start
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expense.merchant.isNotEmpty ? expense.merchant : expense.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          expense.formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        if (expense.receiptImagePath != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.receipt,
                            size: 14,
                            color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // 3. Highlighted monetary amount formatted as Vietnamese Dong (###.### đ)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: expense.amount > 500000
                      ? Colors.red.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  CurrencyFormatter.formatVND(expense.amount),
                  style: TextStyle(
                    color: expense.amount > 500000
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

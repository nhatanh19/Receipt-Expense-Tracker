import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../ocr/domain/parsed_receipt.dart';
import '../../ocr/presentation/receipt_review_dialog.dart';
import '../domain/expense_model.dart';
import '../providers/expense_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final ExpenseItem expense;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              final updated = await ReceiptReviewDialog.show(
                context,
                parsedReceipt: ParsedReceipt.empty(),
                imagePath: expense.receiptImagePath,
                initialExpense: expense,
              );
              if (updated != null) {
                await ref.read(expenseListProvider.notifier).updateExpense(updated);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Xóa',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: const Text('Bạn có chắc chắn muốn xóa hóa đơn này khỏi hệ thống?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(expenseListProvider.notifier).deleteExpense(expense.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount and Merchant Hero Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: expense.category.color.withValues(alpha: 0.15),
                      child: Icon(
                        expense.category.icon,
                        size: 32,
                        color: expense.category.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      expense.merchant.isNotEmpty ? expense.merchant : expense.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      expense.category.displayName,
                      style: TextStyle(
                        color: expense.category.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      CurrencyFormatter.formatVND(expense.amount),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expense.formattedDateTime,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Receipt Photo if captured
            if (expense.receiptImagePath != null && File(expense.receiptImagePath!).existsSync()) ...[
              Text(
                'Ảnh chụp hóa đơn gốc',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  // Full screen image preview dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog.fullscreen(
                      child: Scaffold(
                        appBar: AppBar(
                          title: const Text('Xem ảnh hóa đơn'),
                          leading: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                        body: Center(
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.file(File(expense.receiptImagePath!)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.file(
                      File(expense.receiptImagePath!),
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Raw OCR Recognized Text
            if (expense.rawOcrText != null && expense.rawOcrText!.trim().isNotEmpty) ...[
              Text(
                'Văn bản OCR nhận diện được',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: isDarkMode ? Colors.black26 : Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: SelectableText(
                    expense.rawOcrText!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../expenses/domain/expense_model.dart';
import '../domain/parsed_receipt.dart';

class ReceiptReviewDialog extends StatefulWidget {
  final ParsedReceipt parsedReceipt;
  final String? imagePath;
  final ExpenseItem? initialExpense; // If editing an existing expense

  const ReceiptReviewDialog({
    super.key,
    required this.parsedReceipt,
    this.imagePath,
    this.initialExpense,
  });

  static Future<ExpenseItem?> show(
    BuildContext context, {
    required ParsedReceipt parsedReceipt,
    String? imagePath,
    ExpenseItem? initialExpense,
  }) {
    return showModalBottomSheet<ExpenseItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReceiptReviewDialog(
        parsedReceipt: parsedReceipt,
        imagePath: imagePath,
        initialExpense: initialExpense,
      ),
    );
  }

  @override
  State<ReceiptReviewDialog> createState() => _ReceiptReviewDialogState();
}

class _ReceiptReviewDialogState extends State<ReceiptReviewDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _merchantController;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    final expense = widget.initialExpense;
    final ocr = widget.parsedReceipt;

    _merchantController = TextEditingController(
      text: expense?.merchant ?? (ocr.merchant.isNotEmpty ? ocr.merchant : 'Highlands Coffee'),
    );
    _titleController = TextEditingController(
      text: expense?.title ?? (ocr.merchant.isNotEmpty ? 'Chi tiêu tại ${ocr.merchant}' : 'Hóa đơn chi tiêu'),
    );
    _amountController = TextEditingController(
      text: (expense?.amount ?? (ocr.totalAmount > 0 ? ocr.totalAmount : 0.0)).toInt().toString(),
    );
    _selectedDate = expense?.timestamp ?? ocr.date;
    _selectedCategory = expense?.category ?? ocr.suggestedCategory;
  }

  @override
  void dispose() {
    // Critical memory lifecycle: dispose controllers as taught in Slide 29
    _merchantController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openFullImageViewer(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            title: const Text('Chi tiết hóa đơn gốc'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pinch, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Dùng 2 ngón tay để phóng to / thu nhỏ',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final merchant = _merchantController.text.trim();
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Chi tiêu tại $merchant';

    final result = ExpenseItem(
      id: widget.initialExpense?.id ?? const Uuid().v4(),
      title: title,
      merchant: merchant,
      amount: parsedAmount,
      category: _selectedCategory,
      timestamp: _selectedDate,
      receiptImagePath: widget.imagePath ?? widget.initialExpense?.receiptImagePath,
      rawOcrText: widget.parsedReceipt.rawText.isNotEmpty
          ? widget.parsedReceipt.rawText
          : widget.initialExpense?.rawOcrText,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialExpense == null ? 'Xác nhận hóa đơn OCR' : 'Chỉnh sửa chi tiêu',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.parsedReceipt.confidence > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'OCR: ${(widget.parsedReceipt.confidence * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Image preview with tap to zoom
                if (widget.imagePath != null && File(widget.imagePath!).existsSync()) ...[
                  InkWell(
                    onTap: () => _openFullImageViewer(context, widget.imagePath!),
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: Image.file(
                              File(widget.imagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Gradient & tap hint overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Chạm để phóng to xem chi tiết',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Xem toàn màn hình',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Merchant input
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Tên cửa hàng / Đơn vị',
                    prefixIcon: Icon(Icons.storefront),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên cửa hàng' : null,
                ),
                const SizedBox(height: 14),

                // Amount input
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số tiền (VNĐ)',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixText: 'VNĐ',
                    helperText: _amountController.text.isNotEmpty
                        ? CurrencyFormatter.formatVND(
                            double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
                        : null,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  onChanged: (v) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                    final num = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                    if (num == null || num <= 0) return 'Số tiền không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Date Picker button
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày chi tiêu',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    child: Text(
                      DateFormatter.formatDate(_selectedDate),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Selection
                Text(
                  'Danh mục chi tiêu:',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat.displayName),
                      avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                      selected: isSelected,
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _onSave,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Xác nhận & Lưu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

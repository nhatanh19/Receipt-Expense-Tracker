import '../../../core/constants/app_categories.dart';

class ParsedReceipt {
  final String merchant;
  final double totalAmount;
  final DateTime date;
  final ExpenseCategory suggestedCategory;
  final String rawText;
  final double confidence; // 0.0 to 1.0

  const ParsedReceipt({
    required this.merchant,
    required this.totalAmount,
    required this.date,
    required this.suggestedCategory,
    required this.rawText,
    this.confidence = 0.8,
  });

  // Empty fallback draft
  factory ParsedReceipt.empty() {
    return ParsedReceipt(
      merchant: '',
      totalAmount: 0.0,
      date: DateTime.now(),
      suggestedCategory: ExpenseCategory.other,
      rawText: '',
      confidence: 0.0,
    );
  }

  ParsedReceipt copyWith({
    String? merchant,
    double? totalAmount,
    DateTime? date,
    ExpenseCategory? suggestedCategory,
    String? rawText,
    double? confidence,
  }) {
    return ParsedReceipt(
      merchant: merchant ?? this.merchant,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
    );
  }
}

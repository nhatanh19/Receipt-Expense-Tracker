import '../../../core/constants/app_categories.dart';
import '../../../core/utils/date_formatter.dart';

class ExpenseItem {
  final String id;
  final String title;
  final String merchant;
  final double amount;
  final ExpenseCategory category;
  final DateTime timestamp;
  final String? receiptImagePath;
  final String? rawOcrText;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.merchant,
    required this.amount,
    this.category = ExpenseCategory.other,
    required this.timestamp,
    this.receiptImagePath,
    this.rawOcrText,
  });

  // Named constructor with initializer list as presented in Slide 15
  ExpenseItem.draft(this.title, this.amount, {this.merchant = '', this.category = ExpenseCategory.other})
      : id = "draft_${DateTime.now().millisecondsSinceEpoch}",
        timestamp = DateTime.now(),
        receiptImagePath = null,
        rawOcrText = null;

  String get formattedDate => DateFormatter.formatDate(timestamp);
  String get formattedDateTime => DateFormatter.formatDateTime(timestamp);

  ExpenseItem copyWith({
    String? id,
    String? title,
    String? merchant,
    double? amount,
    ExpenseCategory? category,
    DateTime? timestamp,
    String? receiptImagePath,
    String? rawOcrText,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'merchant': merchant,
      'amount': amount,
      'category': category.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'receipt_image_path': receiptImagePath,
      'raw_ocr_text': rawOcrText,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      merchant: (map['merchant'] as String?) ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategoryX.fromString(map['category'] as String?),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      receiptImagePath: map['receipt_image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
    );
  }
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  utilities,
  entertainment,
  education,
  other,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get displayName => switch (this) {
    ExpenseCategory.food => 'Ăn uống',
    ExpenseCategory.transport => 'Di chuyển',
    ExpenseCategory.shopping => 'Mua sắm',
    ExpenseCategory.utilities => 'Tiện ích & Hóa đơn',
    ExpenseCategory.entertainment => 'Giải trí',
    ExpenseCategory.education => 'Học tập & Sách',
    ExpenseCategory.other => 'Khác',
  };

  IconData get icon => switch (this) {
    ExpenseCategory.food => Icons.restaurant,
    ExpenseCategory.transport => Icons.directions_car,
    ExpenseCategory.shopping => Icons.shopping_bag,
    ExpenseCategory.utilities => Icons.receipt_long,
    ExpenseCategory.entertainment => Icons.movie,
    ExpenseCategory.education => Icons.school,
    ExpenseCategory.other => Icons.category,
  };

  Color get color => switch (this) {
    ExpenseCategory.food => AppColors.food,
    ExpenseCategory.transport => AppColors.transport,
    ExpenseCategory.shopping => AppColors.shopping,
    ExpenseCategory.utilities => AppColors.utilities,
    ExpenseCategory.entertainment => AppColors.entertainment,
    ExpenseCategory.education => AppColors.education,
    ExpenseCategory.other => AppColors.other,
  };

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

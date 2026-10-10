import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/database/app_database.dart';
import '../domain/expense_model.dart';

// Filter state
final selectedCategoryFilterProvider = StateProvider<ExpenseCategory?>((ref) => null);

// Expense List Notifier
final expenseListProvider = StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<ExpenseItem>>>((ref) {
  return ExpenseListNotifier();
});

class ExpenseListNotifier extends StateNotifier<AsyncValue<List<ExpenseItem>>> {
  ExpenseListNotifier() : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final items = await AppDatabase.instance.getAllExpenses();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(ExpenseItem item) async {
    try {
      await AppDatabase.instance.insertExpense(item);
      final currentList = state.value ?? [];
      final updatedList = [item, ...currentList]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = AsyncValue.data(updatedList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExpense(ExpenseItem updatedItem) async {
    try {
      await AppDatabase.instance.updateExpense(updatedItem);
      final currentList = state.value ?? [];
      final newList = currentList.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = AsyncValue.data(newList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await AppDatabase.instance.deleteExpense(id);
      final currentList = state.value ?? [];
      final newList = currentList.where((item) => item.id != id).toList();
      state = AsyncValue.data(newList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Filtered Expenses Provider
final filteredExpenseListProvider = Provider<List<ExpenseItem>>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final categoryFilter = ref.watch(selectedCategoryFilterProvider);

  return asyncExpenses.when(
    data: (expenses) {
      if (categoryFilter == null) return expenses;
      return expenses.where((e) => e.category == categoryFilter).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

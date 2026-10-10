// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/constants/app_categories.dart';
import 'package:vku_expense_ocr/features/ocr/services/heuristic_parser.dart';

void main() {
  group('Real Bills Test with Actual App Parser', () {
    test('Bill 1 - Hoi An Mask Receipt', () {
      final rawText = File('test/bill1_ocr.txt').readAsStringSync();
      final parsed = HeuristicParser.parseReceipt(rawText);

      print('\n================ BILL 1 RESULT ================');
      print('Tên cửa hàng (Merchant): ${parsed.merchant}');
      print('Tổng tiền (Total Amount): ${parsed.totalAmount} đ');
      print('Ngày chi tiêu (Date): ${parsed.date.day}/${parsed.date.month}/${parsed.date.year}');
      print('Danh mục (Category): ${parsed.suggestedCategory.displayName}');
      print('Độ tin cậy (Confidence): ${(parsed.confidence * 100).toInt()}%');
      print('================================================\n');

      expect(parsed.totalAmount, equals(150000.0));
      expect(parsed.date.day, equals(27));
      expect(parsed.date.month, equals(1));
      expect(parsed.date.year, equals(2020));
    });

    test('Bill 2 - Sieu Thi EVMART', () {
      final rawText = File('test/bill2_ocr.txt').readAsStringSync();
      final parsed = HeuristicParser.parseReceipt(rawText);

      print('\n================ BILL 2 RESULT ================');
      print('Tên cửa hàng (Merchant): ${parsed.merchant}');
      print('Tổng tiền (Total Amount): ${parsed.totalAmount} đ');
      print('Ngày chi tiêu (Date): ${parsed.date.day}/${parsed.date.month}/${parsed.date.year}');
      print('Danh mục (Category): ${parsed.suggestedCategory.displayName}');
      print('Độ tin cậy (Confidence): ${(parsed.confidence * 100).toInt()}%');
      print('================================================\n');

      expect(parsed.merchant, contains('EVMART'));
      expect(parsed.suggestedCategory, equals(ExpenseCategory.shopping));
    });

    test('Bill 3 - Bida Phuong Hoang', () {
      final rawText = File('test/bill3_ocr.txt').readAsStringSync();
      final parsed = HeuristicParser.parseReceipt(rawText);

      print('\n================ BILL 3 RESULT ================');
      print('Tên cửa hàng (Merchant): ${parsed.merchant}');
      print('Tổng tiền (Total Amount): ${parsed.totalAmount} đ');
      print('Ngày chi tiêu (Date): ${parsed.date.day}/${parsed.date.month}/${parsed.date.year}');
      print('Danh mục (Category): ${parsed.suggestedCategory.displayName}');
      print('Độ tin cậy (Confidence): ${(parsed.confidence * 100).toInt()}%');
      print('================================================\n');

      expect(parsed.merchant, contains('Bida'));
      expect(parsed.totalAmount, equals(136000.0));
      expect(parsed.date.day, equals(13));
      expect(parsed.date.month, equals(4));
      expect(parsed.date.year, equals(2015));
      expect(parsed.suggestedCategory, equals(ExpenseCategory.entertainment));
    });

    test('Bill 4 - Thiet Bi Tinh Tien Tin Thong', () {
      final rawText = File('test/bill4_ocr.txt.txt').readAsStringSync();
      final parsed = HeuristicParser.parseReceipt(rawText);

      print('\n================ BILL 4 RESULT ================');
      print('Tên cửa hàng (Merchant): ${parsed.merchant}');
      print('Tổng tiền (Total Amount): ${parsed.totalAmount} đ');
      print('Ngày chi tiêu (Date): ${parsed.date.day}/${parsed.date.month}/${parsed.date.year}');
      print('Danh mục (Category): ${parsed.suggestedCategory.displayName}');
      print('Độ tin cậy (Confidence): ${(parsed.confidence * 100).toInt()}%');
      print('================================================\n');

      expect(parsed.totalAmount, greaterThan(0));
    });
  });
}

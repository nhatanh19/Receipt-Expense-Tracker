import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/constants/app_categories.dart';
import 'package:vku_expense_ocr/features/ocr/services/heuristic_parser.dart';

void main() {
  group('HeuristicParser Tests', () {
    test('Correctly extracts Highlands Coffee receipt', () {
      const rawText = '''
PHIẾU THANH TOÁN
HIGHLANDS COFFEE DA NANG
Địa chỉ: 123 Đường 2/9, Hải Châu, Đà Nẵng
Ngày: 22/10/2026 14:30
Thu ngân: NV01
--------------------------------
1 Trà sen vàng       45.000
1 Phin sữa đá        20.000
--------------------------------
TỔNG CỘNG: 65.000 đ
Tiền mặt: 100.000
Tiền thừa: 35.000
Cảm ơn quý khách!
''';

      final result = HeuristicParser.parseReceipt(rawText);

      expect(result.merchant, contains('HIGHLANDS COFFEE'));
      expect(result.totalAmount, equals(65000.0));
      expect(result.date.day, equals(22));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      expect(result.suggestedCategory, equals(ExpenseCategory.food));
    });

    test('Correctly extracts Co.op Mart supermarket receipt', () {
      const rawText = '''
CO.OP MART DA NANG
478 Điện Biên Phủ, Thanh Khê
MST: 0300123456
HÓA ĐƠN BÁN HÀNG
Ngày: 15-09-2026
Sữa tươi tiệt trùng    35,000
Bánh mì sandwich       22,000
Thịt heo sạch         188,000
--------------------------------
THÀNH TIỀN: 245,000 VND
CẢM ƠN QUÝ KHÁCH HÀNG
''';

      final result = HeuristicParser.parseReceipt(rawText);

      expect(result.merchant, contains('CO.OP MART'));
      expect(result.totalAmount, equals(245000.0));
      expect(result.date.day, equals(15));
      expect(result.date.month, equals(9));
      expect(result.date.year, equals(2026));
      expect(result.suggestedCategory, equals(ExpenseCategory.shopping));
    });

    test('Correctly extracts Petrolimex Gas receipt', () {
      const rawText = '''
PETROLIMEX CỬA HÀNG 12
CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM
HÓA ĐƠN ĐIỆN TỬ
Ngày 05/11/2026
Xăng RON 95-III
Đơn giá: 23.500
Số lượng: 2.13 L
TỔNG TIỀN: 50.000 VNĐ
''';

      final result = HeuristicParser.parseReceipt(rawText);

      expect(result.merchant, contains('PETROLIMEX'));
      expect(result.totalAmount, equals(50000.0));
      expect(result.date.day, equals(5));
      expect(result.date.month, equals(11));
      expect(result.date.year, equals(2026));
      expect(result.suggestedCategory, equals(ExpenseCategory.transport));
    });

    test('Correctly extracts Quan An Thien Tan receipt with letter-spaced TIEN MAT and comma-space amount', () {
      const rawText = '''
QUAN AN THIEN TAN
17-19 TON DAN F13Q4 TPHCM
DT: 9407863-8259956
**********
REG      13-11-2011 20:54
CA 1     MC #01      000887
BANSO : 47

1 BUN SING            42,000
1 MI GION X CHAY      37,000
2 MI X GION N         80,000
4 COM BAT BUU        172,000
1 SUON CHIEN KDO      65,000
1 HU TIEU N           40,000
1 TOM LAN BOT         65,000
2 PEPSI               16,000
10 TRA DA             20,000
T I E N   M A T
                     537, 000

CAM ON QUY KHACH
HEN GAP LAI!
''';

      final result = HeuristicParser.parseReceipt(rawText);

      expect(result.merchant, equals('QUAN AN THIEN TAN'));
      expect(result.totalAmount, equals(537000.0));
      expect(result.date.day, equals(13));
      expect(result.date.month, equals(11));
      expect(result.date.year, equals(2011));
      expect(result.suggestedCategory, equals(ExpenseCategory.food));
    });

    test('Handles fallback for empty or degraded text gracefully', () {
      const emptyText = '';
      final emptyResult = HeuristicParser.parseReceipt(emptyText);
      expect(emptyResult.totalAmount, equals(0.0));
      expect(emptyResult.merchant, isEmpty);

      const noisyText = 'HÓA ĐƠN\nVAT\n12345';
      final noisyResult = HeuristicParser.parseReceipt(noisyText);
      expect(noisyResult.totalAmount, equals(12345.0));
    });
  });
}

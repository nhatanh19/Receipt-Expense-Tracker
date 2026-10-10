import '../../../core/constants/app_categories.dart';
import '../domain/parsed_receipt.dart';

class HeuristicParser {
  HeuristicParser._();

  static const List<String> _ignoreMerchantKeywords = [
    'HOA DON',
    'HÓA ĐƠN',
    'VAT',
    'RECEIPT',
    'INVOICE',
    'PHIEU TINH TIEN',
    'PHIẾU TÍNH TIỀN',
    'PHIEU THANH TOAN',
    'PHIẾU THANH TOÁN',
    'BIEN LAI',
    'BIÊN LAI',
    'WELCOME',
    'KINH CHAO',
    'KÍNH CHÀO',
    'CAM ON',
    'CẢM ƠN',
    'THANKS',
    'THANK YOU',
    'TAX CODE',
    'MST',
    'MA SO THUE',
    'MÃ SỐ THUẾ',
    'DIA CHI',
    'ĐỊA CHỈ',
    'TEL',
    'SDT',
    'SĐT',
    'HOTLINE',
    'WIFI',
    'PASSWORD',
    'PASS',
  ];

  static const List<String> _primaryTotalKeywords = [
    'TONG HOA DON',
    'TỔNG HÓA ĐƠN',
    'TONGHOADON',
    'SO TIEN THANH TOAN',
    'SỐ TIỀN THANH TOÁN',
    'SOTIENTHANHTOAN',
    'TONG CONG',
    'TỔNG CỘNG',
    'TONGCONG',
    'TONG TIEN',
    'TỔNG TIỀN',
    'TONGTIEN',
    'CONG TIEN',
    'CỘNG TIỀN',
    'CONGTIEN',
    'THANH TIEN',
    'THÀNH TIỀN',
    'THANHTIEN',
    'TOTAL',
    'GRAND TOTAL',
    'GRANDTOTAL',
    'AMOUNT DUE',
    'AMOUNTDUE',
    'AMOUNT',
    'CAN THANH TOAN',
    'CẦN THANH TOÁN',
    'CANTHANHTOAN',
    'PHAI TRA',
    'PHẢI TRẢ',
    'PHAITRA',
    'TONG:',
    'TỔNG:',
    'TONG :',
    'TỔNG :',
  ];

  static const List<String> _secondaryTotalKeywords = [
    'TIEN MAT',
    'TIỀN MẶT',
    'TIENMAT',
    'CASH',
    'THANH TOAN',
    'THANH TOÁN',
    'THANHTOAN',
  ];

  /// Parses raw OCR text into structured ParsedReceipt
  static ParsedReceipt parseReceipt(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceipt.empty();
    }

    final rawLines = rawText.split('\n');
    final cleanedLines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (cleanedLines.isEmpty) {
      return ParsedReceipt.empty();
    }

    // 1. Extract Merchant Header
    final merchant = _extractMerchant(cleanedLines);

    // 2. Extract Total Amount
    final (amount, amountConfidence) = _extractTotalAmount(cleanedLines);

    // 3. Extract Date
    final (date, dateFound) = _extractDate(cleanedLines);

    // 4. Determine Category
    final category = _detectCategory(merchant, rawText);

    double confidence = 0.5;
    if (merchant.isNotEmpty && merchant != 'Cửa hàng / Dịch vụ') confidence += 0.2;
    if (amount > 0) confidence += 0.2;
    if (dateFound) confidence += 0.1;

    return ParsedReceipt(
      merchant: merchant,
      totalAmount: amount,
      date: date,
      suggestedCategory: category,
      rawText: rawText,
      confidence: (confidence * (amountConfidence > 0 ? amountConfidence : 1.0)).clamp(0.0, 1.0),
    );
  }

  static String _extractMerchant(List<String> lines) {
    // Look within top 6 lines for the first legitimate store name
    final searchLimit = lines.length < 6 ? lines.length : 6;

    for (int i = 0; i < searchLimit; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();

      // Clean leading and trailing noisy symbols (e.g. |, *, `, „)
      var cleaned = line.replaceAll(RegExp(r'^[^a-zA-Z0-9À-ỹ]+|[^a-zA-Z0-9À-ỹ]+$'), '').trim();
      // Remove leading junk prefixes with distorted non-standard glyphs like "giŸ "
      cleaned = cleaned.replaceFirst(RegExp(r'^[a-z0-9]{1,3}[Ÿ~`^\ufffd]\s*'), '').trim();

      // Skip lines that are mostly punctuation or noise (e.g. Lm) " =. tự)
      final letterCount = RegExp(r'[a-zA-ZÀ-ỹ]').allMatches(cleaned).length;
      final nonSpaceCount = cleaned.replaceAll(RegExp(r'\s+'), '').length;
      if (letterCount < 5) continue;
      if (nonSpaceCount > 0 && (letterCount / nonSpaceCount) < 0.65) continue;

      // Check if line contains ignored keywords
      bool isIgnored = false;
      for (final kw in _ignoreMerchantKeywords) {
        if (upper.contains(kw)) {
          isIgnored = true;
          break;
        }
      }

      // Check for phone/date/address/tax pattern
      if (RegExp(r'^(0\d{9}|\+84|\d{1,2}[/-]\d{1,2}|mst|tax|hotline)', caseSensitive: false).hasMatch(cleaned)) {
        isIgnored = true;
      }

      if (!isIgnored && cleaned.length >= 3) {
        return cleaned;
      }
    }

    return lines.isNotEmpty ? lines.first : 'Cửa hàng / Dịch vụ';
  }

  static (double, double) _extractTotalAmount(List<String> lines) {
    // Helper to search a list of keywords
    double? findAmountForKeywords(List<String> keywords) {
      double bestAmount = 0.0;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final upper = line.toUpperCase();
        final collapsed = upper.replaceAll(RegExp(r'[^A-Z0-9À-ỹ]'), '');

        bool isMatch = false;
        for (final kw in keywords) {
          final collapsedKw = kw.replaceAll(RegExp(r'[^A-Z0-9À-ỹ]'), '');
          if (upper.contains(kw) || (collapsedKw.length >= 4 && collapsed.contains(collapsedKw))) {
            isMatch = true;
            break;
          }
        }

        if (isMatch) {
          // 1. Check current line first
          final amount = _parseAmountFromString(line);
          if (amount != null && amount >= 1000) {
            if (amount > bestAmount) {
              bestAmount = amount;
            }
          } else {
            // Only check next line if current keyword line has NO amount (e.g. TIEN MAT \n 537, 000)
            if (i + 1 < lines.length) {
              final nextAmount = _parseAmountFromString(lines[i + 1]);
              if (nextAmount != null && nextAmount >= 1000) {
                if (nextAmount > bestAmount) {
                  bestAmount = nextAmount;
                }
              } else if (i + 2 < lines.length) {
                final nextNextAmount = _parseAmountFromString(lines[i + 2]);
                if (nextNextAmount != null && nextNextAmount >= 1000 && nextNextAmount > bestAmount) {
                  bestAmount = nextNextAmount;
                }
              }
            }
          }
        }
      }
      return bestAmount > 0 ? bestAmount : null;
    }

    // 1. First Priority: Explicit invoice total keywords (TỔNG CỘNG, THÀNH TIỀN, TỔNG HÓA ĐƠN)
    final primaryAmount = findAmountForKeywords(_primaryTotalKeywords);
    if (primaryAmount != null) {
      return (primaryAmount, 0.95);
    }

    // 2. Second Priority: Payment method / tender keywords (TIỀN MẶT, THANH TOÁN)
    final secondaryAmount = findAmountForKeywords(_secondaryTotalKeywords);
    if (secondaryAmount != null) {
      return (secondaryAmount, 0.90);
    }

    // 3. Fallback: Largest valid amount on bill excluding IDs/phones
    double maxAmount = 0.0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isMetadataOrCodeLine(line)) continue;

      final amount = _parseAmountFromString(line);
      if (amount != null && amount >= 1000 && amount < 100000000) {
        if (amount > maxAmount) {
          maxAmount = amount;
        }
      }
    }

    return (maxAmount, maxAmount > 0 ? 0.7 : 0.0);
  }

  static bool _isMetadataOrCodeLine(String line) {
    final upper = line.toUpperCase();
    final collapsed = upper.replaceAll(' ', '');

    // Ignore phone numbers
    if (upper.contains('DT:') || upper.contains('TEL:') || upper.contains('HOTLINE:')) return true;
    if (RegExp(r'\d{6,}-\d{6,}').hasMatch(upper)) return true; // e.g. 9407863-8259956

    // Ignore tables, registers, cashier, check IDs, invoice codes
    if (collapsed.contains('BANSO') || collapsed.contains('BAN:') || collapsed.contains('TABLE')) return true;
    if (collapsed.contains('CA1') || collapsed.contains('CA2') || collapsed.contains('CA3') || collapsed.contains('CASANG')) return true;
    if (collapsed.contains('MC#') || upper.contains('REG ') || upper.contains('STT:')) return true;
    if (collapsed.contains('MAHOADON') || collapsed.contains('SOHD') || collapsed.contains('MST:')) return true;
    if (RegExp(r'(?:SỐ|SO|\$6|HD)\s*:\s*\d+', caseSensitive: false).hasMatch(upper)) return true; // e.g. $6: 20011587

    // Ignore standalone timestamps: e.g. 13-11-2011 20:54
    if (RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\s+\d{1,2}:\d{2}').hasMatch(upper)) return true;

    return false;
  }

  static double? _parseAmountFromString(String text) {
    // 1. Normalize spaces around commas/dots: "537, 000" -> "537,000", "537 . 000" -> "537.000"
    String normalized = text.replaceAllMapped(
      RegExp(r'(\d+)\s*([.,])\s*(\d{3})'),
      (m) => '${m[1]}${m[2]}${m[3]}',
    );
    // Also normalize consecutive space-separated thousands: "537  000" -> "537,000"
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d+)\s{1,2}(\d{3})\b'),
      (m) => '${m[1]},${m[2]}',
    );

    // 2. Match candidate numbers
    final match = RegExp(
      r'(?:[\$₫đ]|VND|VNĐ)?\s*(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?|\d+\s*[kK])\s*(?:[\$₫đ]|VND|VNĐ)?',
      caseSensitive: false,
    ).allMatches(normalized);

    double? bestAmount;

    for (final m in match) {
      String rawNum = m.group(1) ?? '';
      rawNum = rawNum.trim();

      // Exclude numbers with leading zeros (e.g., 000887, 01, 002) - these are IDs/counters!
      if (rawNum.startsWith('00') ||
          (rawNum.startsWith('0') && rawNum.length > 1 && !rawNum.contains('.') && !rawNum.contains(','))) {
        continue;
      }

      // Handle "50k" or "50K"
      if (rawNum.toLowerCase().endsWith('k')) {
        final prefix = double.tryParse(rawNum.substring(0, rawNum.length - 1).trim());
        if (prefix != null) {
          final val = prefix * 1000;
          if (bestAmount == null || val > bestAmount) bestAmount = val;
          continue;
        }
      }

      // Vietnamese receipts standard thousands normalization
      String cleanNum = rawNum.replaceAll(' ', '');
      if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(cleanNum)) {
        cleanNum = cleanNum.replaceAll('.', '');
      } else if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(cleanNum)) {
        cleanNum = cleanNum.replaceAll(',', '');
      } else if (RegExp(r'^\d{1,3}(,\d{3})+\.\d{1,2}$').hasMatch(cleanNum)) {
        cleanNum = cleanNum.replaceAll(',', '');
      } else if (RegExp(r'^\d{1,3}(\.\d{3})+,\d{1,2}$').hasMatch(cleanNum)) {
        cleanNum = cleanNum.replaceAll('.', '').replaceAll(',', '.');
      }

      final parsed = double.tryParse(cleanNum);
      if (parsed != null) {
        // Enforce VND floor: Reject numbers < 1000 unless explicit currency marker ($ or USD)
        if (parsed < 1000 && !text.contains('\$') && !text.toUpperCase().contains('USD')) {
          continue;
        }

        if (bestAmount == null || parsed > bestAmount) {
          bestAmount = parsed;
        }
      }
    }

    return bestAmount;
  }

  static (DateTime, bool) _extractDate(List<String> lines) {
    // Regex 1: dd/MM/yyyy or dd-MM-yyyy or dd/MM/yy with optional whitespace
    final dmyRegex = RegExp(r'\b(0?[1-9]|[12]\d|3[01])\s*[/\-\.]\s*(0?[1-9]|1[0-2])\s*[/\-\.]\s*(20\d{2}|\d{2})\b');
    // Regex 2: yyyy-MM-dd or yyyy/MM/dd
    final ymdRegex = RegExp(r'\b(20\d{2})\s*[/\-\.]\s*(0?[1-9]|1[0-2])\s*[/\-\.]\s*(0?[1-9]|[12]\d|3[01])\b');
    // Regex 3: Vietnamese "Ngày 22 tháng 10 năm 2026"
    final vnDateRegex = RegExp(r'Ngày\s*(\d{1,2})\s*tháng\s*(\d{1,2})\s*năm\s*(20\d{2})', caseSensitive: false);
    // Regex 4: OCR merged day-month "2308/2022"
    final mergedDateRegex = RegExp(r'\b(0?[1-9]|[12]\d|3[01])(0[1-9]|1[0-2])\s*[/\-\.]\s*(20\d{2}|\d{2})\b');

    for (final line in lines) {
      final vnMatch = vnDateRegex.firstMatch(line);
      if (vnMatch != null) {
        final d = int.parse(vnMatch.group(1)!);
        final m = int.parse(vnMatch.group(2)!);
        final y = int.parse(vnMatch.group(3)!);
        return (DateTime(y, m, d), true);
      }

      final dmyMatch = dmyRegex.firstMatch(line);
      if (dmyMatch != null) {
        final d = int.parse(dmyMatch.group(1)!);
        final m = int.parse(dmyMatch.group(2)!);
        int y = int.parse(dmyMatch.group(3)!);
        if (y < 100) y += 2000;
        return (DateTime(y, m, d), true);
      }

      final ymdMatch = ymdRegex.firstMatch(line);
      if (ymdMatch != null) {
        final y = int.parse(ymdMatch.group(1)!);
        final m = int.parse(ymdMatch.group(2)!);
        final d = int.parse(ymdMatch.group(3)!);
        return (DateTime(y, m, d), true);
      }

      final mergedMatch = mergedDateRegex.firstMatch(line);
      if (mergedMatch != null) {
        final d = int.parse(mergedMatch.group(1)!);
        final m = int.parse(mergedMatch.group(2)!);
        int y = int.parse(mergedMatch.group(3)!);
        if (y < 100) y += 2000;
        return (DateTime(y, m, d), true);
      }
    }

    // Regex 5: Invoice code HDddMMyy or HDddMMyyyy (e.g. HD120819-0005 -> 12/08/2019)
    final hdDateRegex = RegExp(r'\bHD\s*(\d{2})(\d{2})(\d{2,4})\b', caseSensitive: false);
    for (final line in lines) {
      final hdMatch = hdDateRegex.firstMatch(line);
      if (hdMatch != null) {
        final d = int.parse(hdMatch.group(1)!);
        final m = int.parse(hdMatch.group(2)!);
        int y = int.parse(hdMatch.group(3)!);
        if (d >= 1 && d <= 31 && m >= 1 && m <= 12) {
          if (y < 100) y += 2000;
          return (DateTime(y, m, d), true);
        }
      }
    }

    return (DateTime.now(), false);
  }

  static ExpenseCategory _detectCategory(String merchant, String fullText) {
    final merchantLower = merchant.toLowerCase();
    final lower = fullText.toLowerCase();

    // 1. Supermarket / Grocery / Pharmacy Brands in Merchant or text take priority for Shopping
    if (RegExp(r'(co\.op|coop|winmart|vinmart|bách hóa xanh|bach hoa xanh|siêu thị|sieu thi|circle k|ministop|family mart|7-eleven|shopee|tiki|lazada|mart|khẩu trang|khau trang|nhà thuốc|nha thuoc|pharmacity|long châu|y tế|y te)').hasMatch(merchantLower) ||
        RegExp(r'(khẩu trang|khau trang|y tế|y te|nhà thuốc|nha thuoc)').hasMatch(lower)) {
      return ExpenseCategory.shopping;
    }

    // 2. Entertainment (Bida, Cinema, Karaoke...)
    if (RegExp(r'(bida|bi-da|billiards|cinema|rạp|rap|cgv|lotte cinema|bhd|vé xem phim|ve xem phim|karaoke|game|net)').hasMatch(merchantLower) ||
        RegExp(r'(bida|bi-da|billiards|karaoke|vé xem phim|ve xem phim)').hasMatch(lower)) {
      return ExpenseCategory.entertainment;
    }

    // 3. Transport Brands / Keywords
    if (RegExp(r'(grab|be|gojek|xăng|xang|petrolimex|pvoil|gửi xe|gui xe|giữ xe|giu xe|taxi|mai linh|vé xe|ve xe|vé tàu|ve tau|vé máy bay|ve may bay|vé bus|ve bus)').hasMatch(merchantLower) ||
        RegExp(r'(xăng|xang|petrolimex|pvoil|gửi xe|gui xe|giữ xe|giu xe|cuốc xe|cuoc xe|chuyến xe|chuyen xe)').hasMatch(lower)) {
      return ExpenseCategory.transport;
    }

    // 4. Food & Dining (Accent + Unaccented POS receipt support)
    if (RegExp(r'(coffee|ca phe|cà phê|highlands|tra da|trà đá|tra|trà|tea|com|cơm|pho|phở|bun|bún|banh|bánh|pizza|kfc|lotteria|nha hang|nhà hàng|quan an|quán ăn|quan|quán|nuoc|nước|an vat|ăn vặt|starbucks|che|chè|ga ran|gà rán|mi|mì|hu tieu|hủ tiếu|lau|lẩu|nuong|nướng)').hasMatch(lower)) {
      return ExpenseCategory.food;
    }

    // 5. Shopping / Clothing general
    if (RegExp(r'(co\.op|coop|winmart|vinmart|bách hóa xanh|bach hoa xanh|siêu thị|sieu thi|circle k|ministop|family mart|7-eleven|shopee|tiki|lazada|mua sắm|mua sam|quần áo|quan ao|thời trang|thoi trang)').hasMatch(lower)) {
      return ExpenseCategory.shopping;
    }

    // 6. Utilities
    if (RegExp(r'(tiền điện|tien dien|tiền nước|tien nuoc|internet|viettel|fpt|vnpt|mobifone|hóa đơn điện|hoa don dien|tiện ích|tien ich|nạp thẻ|nap the)').hasMatch(lower)) {
      return ExpenseCategory.utilities;
    }

    // 7. Education
    if (RegExp(r'(vku|sách|sach|vở|vo|giáo trình|giao trinh|học phí|hoc phi|in ấn|in an|photocopy|photo|nhà sách|nha sach|fahasa|dụng cụ học tập|dung cu hoc tap)').hasMatch(lower)) {
      return ExpenseCategory.education;
    }

    return ExpenseCategory.other;
  }
}

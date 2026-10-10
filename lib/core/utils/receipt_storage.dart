import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ReceiptStorage {
  ReceiptStorage._();

  /// Saves a receipt file to permanent app document storage
  static Future<String> saveReceiptImage(File tempFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
    
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final ext = p.extension(tempFile.path).isNotEmpty ? p.extension(tempFile.path) : '.jpg';
    final fileName = 'receipt_${const Uuid().v4()}$ext';
    final savedPath = p.join(receiptsDir.path, fileName);

    await tempFile.copy(savedPath);
    return savedPath;
  }
}

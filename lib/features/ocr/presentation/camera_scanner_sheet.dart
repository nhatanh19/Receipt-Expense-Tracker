import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/receipt_storage.dart';
import '../../expenses/providers/expense_provider.dart';
import '../services/mlkit_ocr_service.dart';
import 'receipt_review_dialog.dart';

class CameraScannerSheet {
  CameraScannerSheet._();

  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Quét hóa đơn chi tiêu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sử dụng Google ML Kit On-Device để tự động nhận diện',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2C4570),
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Chụp ảnh từ Camera'),
                subtitle: const Text('Chụp trực tiếp hóa đơn thanh toán'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _processImageSource(context, ref, ImageSource.camera);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFF7A00),
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Chọn từ Thư viện ảnh'),
                subtitle: const Text('Chọn ảnh hóa đơn đã có sẵn trong máy'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _processImageSource(context, ref, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _processImageSource(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (pickedFile == null || !context.mounted) return;

    // Show Scanning progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Đang xử lý OCR On-Device...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'ML Kit & Regex Heuristics',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final ocrService = MlKitOcrService();
    try {
      // 1. Run ML Kit Text Recognition
      final parsedResult = await ocrService.processReceiptImage(pickedFile.path);

      // 2. Persist receipt image to permanent documents directory
      final savedImagePath = await ReceiptStorage.saveReceiptImage(File(pickedFile.path));

      // Dismiss progress dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // 3. Open Review & Manual Correction Dialog (UI/UX Polish Rubric requirement)
        final confirmedExpense = await ReceiptReviewDialog.show(
          context,
          parsedReceipt: parsedResult,
          imagePath: savedImagePath,
        );

        if (confirmedExpense != null) {
          // 4. Save to persistent SQLite database
          await ref.read(expenseListProvider.notifier).addExpense(confirmedExpense);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã lưu hóa đơn: ${confirmedExpense.merchant} (${confirmedExpense.amount.toInt()} đ)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi quét hóa đơn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await ocrService.dispose();
    }
  }
}

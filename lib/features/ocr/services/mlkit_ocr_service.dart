import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/parsed_receipt.dart';
import 'heuristic_parser.dart';

class MlKitOcrService {
  final TextRecognizer _textRecognizer;

  MlKitOcrService()
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Run on-device text recognition on the given image path and parse receipt fields
  Future<ParsedReceipt> processReceiptImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final rawText = recognizedText.text;

    // Run Heuristic Parser
    return HeuristicParser.parseReceipt(rawText);
  }

  /// Close recognizer to free native resources
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

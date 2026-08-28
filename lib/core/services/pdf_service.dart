import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Extracts plain text from PDF file bytes.
  String extractTextFromPdfBytes(Uint8List bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String extractedText = extractor.extractText();
      document.dispose();

      debugPrint("PdfService extracted ${extractedText.length} characters from PDF.");
      return extractedText;
    } catch (e, st) {
      debugPrint("PdfService extractTextFromPdfBytes error: $e\n$st");
      return '';
    }
  }
}

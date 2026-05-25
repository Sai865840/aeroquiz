// ==========================================================================
// Client-Side PDF Selection & Parsing Service (Pure Dart)
// ==========================================================================

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  // Prompts file picker modal for PDF selection
  static Future<FilePickerResult?> pickPdf() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Cache bytes in memory for fast parsing
    );
  }

  // Parses PDF array streams page-by-page and triggers a progress callback
  static Future<Map<String, dynamic>> extractText({
    required List<int> bytes,
    required Function(String title, double fraction) onProgress,
  }) async {
    try {
      // Initialize Syncfusion PDF Document
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      
      if (pageCount == 0) {
        throw Exception('The uploaded PDF is empty.');
      }

      String fullExtractedText = '';
      
      // Page loop for reporting incremental text extraction progress
      for (int i = 0; i < pageCount; i++) {
        final double progressFraction = (i + 1) / pageCount;
        onProgress("Reading PDF page ${i + 1} of $pageCount...", progressFraction);
        
        // Extract text from the page index
        final String pageText = PdfTextExtractor(document).extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        fullExtractedText += pageText + '\n';
      }

      document.dispose(); // dispose bindings to free memory
      
      return {
        'success': true,
        'text': fullExtractedText.trim(),
        'pages': pageCount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

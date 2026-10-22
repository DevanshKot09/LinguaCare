import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'summary_document.dart';
import 'pdf_renderer.dart';

class ExportService {
  static Future<void> exportAndShare(SummaryDocument doc) async {
    final pdfBytes = await PdfRenderer.renderSummary(doc);
    final nowStr = doc.generatedDate;
    final filename = 'LinguaCare_summary_$nowStr.pdf';

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );

      // Clean up temp file
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Fallback sharing via printing if temp file write fails
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    }
  }
}

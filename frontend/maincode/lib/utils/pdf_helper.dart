import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PdfHelper {
  static Future<void> generateReport(String petName, Map<String, dynamic> data, Uint8List chartImage) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(chartImage);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final bool isRisk = data['is_risk'] ?? false;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Clinical Report: $petName", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              // THE GRAPH IMAGE
              pw.Center(child: pw.Image(image, width: 400)),

              pw.SizedBox(height: 20),
              pw.Text("Clinical Insight:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(data['message'] ?? ''),
              pw.SizedBox(height: 10),
              pw.Text("Baseline (Average): ${data['baseline']}"),
              pw.Text("Current Reading: ${data['current']}"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Date & Time', 'Recorded Value'],
                data: (data['points'] as List).map((p) => [
                  p['date'].toString(), // Use the new date string from backend
                  "${p['y']} kg"
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfHelper {
  static Future<void> generateReport(String petName, Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final bool isRisk = data['is_risk'] ?? false;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("PetSync Health Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Patient: $petName"),
              pw.Text("Status: ${isRisk ? "⚠️ ATTENTION REQUIRED" : "✅ HEALTH STABLE"}"),
              pw.SizedBox(height: 20),
              pw.Text("Clinical Insight:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(data['message'] ?? ""),
              pw.SizedBox(height: 10),
              pw.Text("Baseline (Average): ${data['baseline']}"),
              pw.Text("Current Reading: ${data['current']}"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Log Index', 'Value'],
                  ... (data['points'] as List).map((p) => [p['x'].toString(), p['y'].toString()]).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    // This opens the in-app preview/print dialog
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
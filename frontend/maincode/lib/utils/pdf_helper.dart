// Generates and prints a formatted PDF health report for a pet metric.
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart' show DateTimeRange;

class PdfHelper {
  static Future<void> generateReport(String petName, String metricName, Map<String, dynamic> data, Uint8List chartImage, {DateTimeRange? dateRange}) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(chartImage);

    // Extract the points for the table
    final List<dynamic> points = data['points'] ?? [];

    pdf.addPage(
      pw.MultiPage( // Changed to MultiPage in case the table is long
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Clinical Health Report: $petName",
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                    pw.Text(metricName.replaceAll('_', ' ').toUpperCase(),
                      style: pw.TextStyle(fontSize: 13, color: PdfColors.teal700, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Text(DateTime.now().toString().substring(0, 10), style: const pw.TextStyle(color: PdfColors.grey700)),
              ],
            ),
            if (dateRange != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  "Date range: ${dateRange.start.day}/${dateRange.start.month}/${dateRange.start.year} – ${dateRange.end.day}/${dateRange.end.month}/${dateRange.end.year}",
                  style: const pw.TextStyle(color: PdfColors.grey700),
                ),
              ),
            pw.Divider(thickness: 2, color: PdfColors.teal),
            pw.SizedBox(height: 20),

            // CHART SECTION
            pw.Text("Visual Trend Analysis", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Container(
              height: 250,
              child: pw.Image(image),
            )),
            pw.SizedBox(height: 20),

            // INSIGHT SECTION
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Clinical Insight:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  // Strip emoji characters — the pdf package renders them as blank boxes.
                  pw.Text((data['message'] ?? 'No anomalies detected in the current period.').replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]|[\u{2600}-\u{27BF}]', unicode: true), '').trim()),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Text("Baseline Average: ${(double.tryParse(data['baseline'].toString()) ?? 0.0).toStringAsFixed(2)} "),
                      pw.SizedBox(width: 20),
                      pw.Text("Latest Reading: ${(double.tryParse(data['current'].toString()) ?? 0.0).toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // --- THE DATA TABLE ---
            pw.Text("Raw Inputted Values", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.center,
              // Define the columns
              headers: <String>['Date & Time', 'Value Inputted', 'Status'],
              // Map your data points to rows
              data: points.map((p) {
                // Calculate if point is above/below baseline for the 'Status' column
                double val = double.tryParse(p['y'].toString()) ?? 0.0;
                double base = double.tryParse(data['baseline'].toString()) ?? 0.0;
                String status = val >= base ? "Normal/Optimal" : "Below Baseline";

                return [
                  p['date'].toString(), 
                  "${p['y']} ${data['unit'] ?? ''}",
                  status
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PrintReportUtils {
  static Future<void> showPrintPreview(
    BuildContext context, {
    required String title,
    required List<String> columns,
    required List<List<String>> data,
    String? subtitle,
  }) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 900,
          height: 800,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Report Preview",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PdfPreview(
                  build: (format) => _generatePdf(
                    format,
                    title: title,
                    subtitle: subtitle,
                    columns: columns,
                    data: data,
                  ),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  dynamicLayout: true,
                  initialPageFormat: PdfPageFormat.a4,
                  pdfFileName: "${title.replaceAll(' ', '_').toLowerCase()}.pdf",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<Uint8List> _generatePdf(
    PdfPageFormat format, {
    required String title,
    required List<String> columns,
    required List<List<String>> data,
    String? subtitle,
  }) async {
    final logo = await imageFromAssetBundle('assets/logo/jhcsc.png');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(logo, width: 40, height: 40),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "JHCSC LIBRARY",
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800,
                          ),
                        ),
                        pw.Text(
                          "Official Management Report",
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      "Page ${context.pageNumber} of ${context.pagesCount}",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.green800),
            pw.SizedBox(height: 20),
          ],
        ),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                if (subtitle != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          pw.TableHelper.fromTextArray(
            headers: columns,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellHeight: 30,
            cellAlignments: {
              for (var i = 0; i < columns.length; i++) i: pw.Alignment.centerLeft,
            },
            cellStyle: const pw.TextStyle(fontSize: 10),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Total Records: ${data.length}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.Text(
                "Generated by Library Management System",
                style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }
}

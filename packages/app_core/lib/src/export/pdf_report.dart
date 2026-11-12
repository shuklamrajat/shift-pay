import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// A titled block of rows inside a report.
class PdfTableSection {
  const PdfTableSection({
    required this.heading,
    required this.headers,
    required this.rows,
    this.columnAlignRight = const {},
    this.footer = const [],
  });
  final String heading;
  final List<String> headers;
  final List<List<String>> rows;
  final Set<int> columnAlignRight;
  final List<String> footer;
}

/// Free-form block: optional image and a list of label/value lines.
class PdfDetailBlock {
  const PdfDetailBlock({required this.title, required this.lines, this.images = const []});
  final String title;
  final List<(String, String)> lines;
  final List<Uint8List> images;
}

/// Builds a plain, printable report: title, meta lines, summary pairs, then
/// table sections and detail blocks. Page numbers in the footer.
Future<Uint8List> buildPdfReport({
  required String title,
  List<String> meta = const [],
  List<(String, String)> summary = const [],
  List<PdfTableSection> tables = const [],
  List<PdfDetailBlock> details = const [],
  String? footerNote,
}) async {
  // Embedded Roboto so currency symbols and accented names render; the
  // built-in PDF fonts only cover Latin-1.
  final regular = pw.Font.ttf(await rootBundle.load('packages/app_core/assets/fonts/Roboto-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('packages/app_core/assets/fonts/Roboto-Bold.ttf'));
  final doc = pw.Document(
    title: title,
    creator: 'app_core',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
  const cellStyle = pw.TextStyle(fontSize: 9);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    footer: (ctx) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(footerNote ?? '', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
    build: (ctx) => [
      pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      for (final m in meta) pw.Text(m, style: const pw.TextStyle(fontSize: 10)),
      if (summary.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Table(
          columnWidths: const {0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth()},
          children: [
            for (final (k, v) in summary)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.only(right: 12, bottom: 2), child: pw.Text(k, style: headerStyle)),
                pw.Text(v, style: cellStyle),
              ]),
          ],
        ),
      ],
      for (final t in tables) ...[
        pw.SizedBox(height: 14),
        pw.Text(t.heading, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headers: t.headers,
          data: t.rows,
          headerStyle: headerStyle,
          cellStyle: cellStyle,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            for (var i = 0; i < t.headers.length; i++)
              i: t.columnAlignRight.contains(i) ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          },
        ),
        for (final f in t.footer)
          pw.Padding(padding: const pw.EdgeInsets.only(top: 3), child: pw.Text(f, style: headerStyle)),
      ],
      for (final d in details)
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: 0.5)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(d.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            for (final (k, v) in d.lines)
              pw.Text('$k: $v', style: cellStyle),
            if (d.images.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Wrap(spacing: 6, runSpacing: 6, children: [
                for (final img in d.images)
                  pw.Image(pw.MemoryImage(img), width: 150, height: 110, fit: pw.BoxFit.contain),
              ]),
            ],
          ]),
        ),
    ],
  ));
  return doc.save();
}

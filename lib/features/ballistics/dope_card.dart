import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// DOPE kartı (owner, 2026-10-09): the range / clicks table of the active
/// profile as a printable PDF, prepared before going to the field. Pure
/// data in, PDF bytes out, so it is testable without the share sheet.
class DopeCardData {
  final String title;

  /// Short "label: value" lines under the title (rifle, ammo, zero, scope,
  /// weather, date).
  final List<(String, String)> info;
  final List<String> headers;
  final List<List<String>> rows;

  /// Notes printed under the table (assumptions, warnings).
  final List<String> notes;

  const DopeCardData({
    required this.title,
    required this.info,
    required this.headers,
    required this.rows,
    this.notes = const [],
  });
}

/// Builds the A4 card. [regular] and [bold] are TrueType fonts with Turkish
/// glyphs (the built-in PDF fonts have no ı, ş, ğ).
Future<Uint8List> buildDopeCardPdf(
  DopeCardData d, {
  required ByteData regular,
  required ByteData bold,
}) async {
  final doc = pw.Document(title: d.title, author: 'Sniper Türk');
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(regular),
    bold: pw.Font.ttf(bold),
  );
  const ink = PdfColor.fromInt(0xFF0F2230);
  const red = PdfColor.fromInt(0xFFC8102E);
  const grey = PdfColor.fromInt(0xFF465D6F);
  const band = PdfColor.fromInt(0xFFEFF3F5);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: theme,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'SNIPER ',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
              pw.Text(
                'TÜRK',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: red,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                'DOPE KARTI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: grey,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            d.title,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: ink,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 14,
            runSpacing: 3,
            children: [
              for (final (k, v) in d.info)
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '$k: ',
                        style: const pw.TextStyle(fontSize: 9, color: grey),
                      ),
                      pw.TextSpan(
                        text: v,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: d.headers,
            data: d.rows,
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: ink),
            cellStyle: const pw.TextStyle(fontSize: 11, color: ink),
            cellAlignment: pw.Alignment.center,
            headerAlignment: pw.Alignment.center,
            oddRowDecoration: const pw.BoxDecoration(color: band),
            cellPadding: const pw.EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 4,
            ),
            border: pw.TableBorder.all(color: grey, width: 0.4),
          ),
          pw.SizedBox(height: 10),
          for (final n in d.notes)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                '• $n',
                style: const pw.TextStyle(fontSize: 8.5, color: grey),
              ),
            ),
        ],
      ),
    ),
  );
  return doc.save();
}

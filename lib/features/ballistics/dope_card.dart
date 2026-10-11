import 'dart:math' as math;
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
/// glyphs (the built-in PDF fonts have no ı, ş, ğ); [fallback] supplies the
/// signs they lack (arrows). [logo] (PNG) sits left of "SNIPER TÜRK" and,
/// faded, in the middle of the page (owner, 2026-10-11).
Future<Uint8List> buildDopeCardPdf(
  DopeCardData d, {
  required ByteData regular,
  required ByteData bold,
  ByteData? fallback,
  Uint8List? logo,
}) async {
  final doc = pw.Document(title: d.title, author: 'Sniper Türk');
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(regular),
    bold: pw.Font.ttf(bold),
    fontFallback: [if (fallback != null) pw.Font.ttf(fallback)],
  );
  const ink = PdfColor.fromInt(0xFF0F2230);
  const red = PdfColor.fromInt(0xFFC8102E);
  const grey = PdfColor.fromInt(0xFF465D6F);
  const band = PdfColor.fromInt(0xFFEFF3F5);
  // The table fills the A4 page (owner, 2026-10-11): rows grow with the
  // free height left by the header, the info line and the notes.
  final rowCount = math.max(1, d.rows.length);
  final free = 842.0 - 56 - 100 - 24 - 26 - d.notes.length * 13.0;
  // 10 % reserve so a wrapped info line never pushes past the page.
  final rowH = (free * 0.9 / rowCount).clamp(20.0, 48.0);
  final cellFont = (rowH * 0.42).clamp(11.0, 17.0);
  final cellPadV = ((rowH - cellFont * 1.25) / 2).clamp(4.0, 16.0);
  doc.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        // The logo, faded, in the middle of the page.
        buildBackground: logo == null
            ? null
            : (context) => pw.FullPage(
                ignoreMargins: true,
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.15,
                    child: pw.Image(pw.MemoryImage(logo), width: 240),
                  ),
                ),
              ),
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Image(pw.MemoryImage(logo), height: 34),
                pw.SizedBox(width: 8),
              ],
              pw.Text(
                'SNIPER ',
                style: const pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
              pw.Text(
                'TÜRK',
                style: const pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: red,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                'DOPE KARTI',
                style: const pw.TextStyle(
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
            style: const pw.TextStyle(
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
                        style: const pw.TextStyle(
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
              fontSize: math.min(13, cellFont),
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: ink),
            cellStyle: pw.TextStyle(fontSize: cellFont, color: ink),
            cellAlignment: pw.Alignment.center,
            headerAlignment: pw.Alignment.center,
            oddRowDecoration: const pw.BoxDecoration(color: band),
            cellPadding: pw.EdgeInsets.symmetric(
              vertical: cellPadV,
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

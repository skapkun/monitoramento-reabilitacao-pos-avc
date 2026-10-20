import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    required this.title,
    required this.filename,
    required this.bytes,
    super.key,
  });

  final String title;
  final String filename;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: PdfPreview(
      build: (_) async => bytes,
      pdfFileName: filename,
      allowSharing: true,
      allowPrinting: true,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
    ),
  );
}

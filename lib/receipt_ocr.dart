import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import 'receipt_ocr_native.dart'
    if (dart.library.js_interop) 'receipt_ocr_web.dart'
    as engine;

Future<XFile?> pickReceiptPhoto() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(
      label: 'Foto struk',
      extensions: ['jpg', 'jpeg', 'png'],
      mimeTypes: ['image/jpeg', 'image/png'],
      uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
    ),
  ],
);

Future<String> recognizeReceipt(XFile file, Uint8List bytes) =>
    engine.readReceiptText(file, bytes);

/// Returns the total as written on the receipt, when it has a clear label.
String? receiptTotal(String text) {
  final totalLine = RegExp(
    r'^[ \t]*(?:grand[ \t]+total|total[ \t]+(?:bayar|pembayaran)|jumlah[ \t]+bayar|total)\b[ \t:]*([^\n]*)',
    caseSensitive: false,
    multiLine: true,
  );
  final amount = RegExp(r'(?:Rp\.?\s*)?\d[\d.,]*', caseSensitive: false);
  for (final match in totalLine.allMatches(text)) {
    final tail = match[1]!.trim();
    final candidate = tail.isEmpty
        ? text.substring(match.end).trimLeft().split('\n').first.trim()
        : tail;
    final value = amount.stringMatch(candidate);
    if (value != null && value == candidate) {
      return value;
    }
  }
  return null;
}

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:platform_text_recognition/platform_text_recognition.dart';

Future<String> readReceiptText(XFile file, Uint8List bytes) =>
    recognizeTextFromImage(file.path);

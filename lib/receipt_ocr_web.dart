import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

@JS('chrysosRecognizeReceipt')
external JSPromise<JSString> _recognize(JSUint8Array bytes);

Future<String> readReceiptText(XFile file, Uint8List bytes) async =>
    (await _recognize(bytes.toJS).toDart).toDart;

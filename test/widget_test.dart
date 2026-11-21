import 'dart:async';

import 'package:chrysos/main.dart';
import 'package:chrysos/orbital_scan.dart';
import 'package:chrysos/receipt_ocr.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List image;
  setUpAll(() async {
    final fonts = FontLoader('ChrysosSans');
    for (final weight in ['regular', 'medium', 'bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/roboto-$weight.ttf'));
    }
    await fonts.load();
    image = (await rootBundle.load('assets/chrysos-logo.png')).buffer
        .asUint8List();
  });

  Future<void> openApp(
    WidgetTester tester,
    MyApp app, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Select photo, run OCR on demand, merge, and clear the Scan space',
    (tester) async {
      final scan = Completer<String>();
      var scanCount = 0;
      await openApp(
        tester,
        MyApp(
          pickPhoto: () async =>
              XFile.fromData(image, path: 'warung.png', name: 'warung.png'),
          readReceipt: (file, bytes) async {
            scanCount++;
            expect(file.name, 'warung.png');
            expect(bytes, image);
            return scan.future;
          },
        ),
      );

      expect(find.text('Chrysos'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Scan Now'), findsNothing);
      await tester.tap(find.text('Upload gambar'));
      await tester.pumpAndSettle();
      expect(find.text('warung.png'), findsOneWidget);
      expect(find.bySemanticsLabel('Pratinjau foto struk'), findsOneWidget);
      expect(scanCount, 0);
      expect(find.byType(OrbitalScan), findsNothing);

      await tester.tap(find.text('Scan Now'));
      await tester.pump();
      expect(scanCount, 1);
      expect(find.byType(OrbitalScan), findsOneWidget);
      final angle = tester.widget<OrbitalScan>(find.byType(OrbitalScan)).angle;
      await tester.pump(const Duration(milliseconds: 230));
      expect(
        tester.widget<OrbitalScan>(find.byType(OrbitalScan)).angle,
        greaterThan(angle),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Teks berhasil dibaca'), findsNothing);
      expect(
        tester.widget<OrbitalScan>(find.byType(OrbitalScan)).completion,
        0,
      );
      expect(
        tester.widget<FilledButton>(find.bySubtype<FilledButton>()).onPressed,
        isNull,
      );

      scan.complete('WARUNG PAGI\nTOTAL Rp 48.500');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      expect(
        tester.widget<OrbitalScan>(find.byType(OrbitalScan)).completion,
        greaterThan(.5),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rp 48.500'), findsOneWidget);
      expect(find.byType(OrbitalScan), findsNothing);
      await tester.tap(find.text('Sesi baru'));
      await tester.pumpAndSettle();
      expect(find.text('Upload gambar'), findsOneWidget);
      expect(find.text('warung.png'), findsNothing);
      expect(find.text('Rp 48.500'), findsNothing);
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('warung.png'), findsOneWidget);
      expect(find.text('Rp 48.500'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Invalid and unreadable photos do not show success', (
    tester,
  ) async {
    var picks = 0;
    await openApp(
      tester,
      MyApp(
        pickPhoto: () async {
          picks++;
          return XFile.fromData(
            picks == 1 ? Uint8List(10) : image,
            name: 'struk.png',
          );
        },
        readReceipt: (file, bytes) async => ' ',
      ),
      size: const Size(320, 700),
    );

    await tester.tap(find.text('Upload gambar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pilih foto JPG'), findsOneWidget);
    expect(find.text('Scan Now'), findsNothing);
    await tester.tap(find.text('Upload gambar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan Now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('Teks belum terbaca'), findsOneWidget);
    expect(find.text('Scan Now'), findsOneWidget);
    expect(find.text('Teks berhasil dibaca'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Extracts a clearly labeled receipt total and ignores subtotals', () {
    expect(
      receiptTotal('SUBTOTAL 37.000\nTOTAL BAYAR Rp 48.500\nKEMBALI 1.500'),
      'Rp 48.500',
    );
    expect(receiptTotal('WARUNG PAGI\nGRAND TOTAL\n48.500\n'), '48.500');
    expect(receiptTotal('SUBTOTAL 37.000\nTOTAL ITEM 3'), isNull);
  });
}

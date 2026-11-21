import 'package:chrysos/main.dart';
import 'package:chrysos/orbital_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Arus');
    for (final weight in ['regular', 'medium', 'bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/roboto-$weight.ttf'));
    }
    await fonts.load();
  });
  Future<void> openApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Scan runs through orbital merge, records one result, and can replay',
    (tester) async {
      await openApp(tester);
      expect(find.text('Siap membaca bukti'), findsOneWidget);
      await tester.tap(find.text('Pindai bukti ini'));
      await tester.pump();
      expect(find.text('Membaca bukti'), findsOneWidget);
      expect(
        tester.widget<OrbitalScan>(find.byType(OrbitalScan)).active,
        isTrue,
      );
      // A second tap while scanning must not restart the timeline.
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.tap(find.text('Sedang membaca bukti...'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mengidentifikasi transaksi'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2700));
      expect(find.text('Merapikan catatan'), findsOneWidget);
      expect(
        tester.widget<OrbitalScan>(find.byType(OrbitalScan)).progress,
        greaterThan(0.85),
      );
      await tester.pumpAndSettle();
      expect(find.text('Berhasil dicatat'), findsOneWidget);
      expect(find.text('Rp 35.000', findRichText: true), findsOneWidget);
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('1 transaksi · sesi preview ini'), findsOneWidget);
      await tester.tap(find.text('Warung Bu Prapto'));
      await tester.pumpAndSettle();
      expect(find.text('Berhasil dicatat'), findsOneWidget);
      await tester.tap(find.text('Pindai lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Siap membaca bukti'), findsOneWidget);
      await tester.tap(find.text('Pindai bukti ini'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('1 transaksi · sesi preview ini'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Settings switch appearance and shorten the scan animation', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Atur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode gelap'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Mode gelap'),
          )
          .value,
      isFalse,
    );
    await tester.tap(find.text('Animasi penuh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pindai bukti ini'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();
    expect(find.text('Berhasil dicatat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 700), const Size(1440, 900)]) {
    testWidgets('Layout and scan work at ${size.width} × ${size.height}', (
      tester,
    ) async {
      await openApp(tester, size: size);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Pindai bukti ini'));
      await tester.tap(find.text('Pindai bukti ini'));
      await tester.pumpAndSettle();
      expect(find.text('Berhasil dicatat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'History starts empty and scan can continue while on another tab',
    (tester) async {
      await openApp(tester);
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Mulai dari satu bukti.'), findsOneWidget);
      await tester.tap(find.text('Coba pindai bukti'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pindai bukti ini'));
      await tester.pump();
      await tester.tap(find.text('Atur'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('1 transaksi · sesi preview ini'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

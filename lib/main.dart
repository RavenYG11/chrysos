import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import 'orbital_scan.dart';
import 'receipt_ocr.dart';

void main() => runApp(const MyApp());

const _lavender = Color(0xFFAD91FF);
const _mint = Color(0xFF97DCC0);
const _logo = 'assets/chrysos-logo.png';
const _maxPhotoBytes = 15 * 1024 * 1024;
typedef PhotoPicker = Future<XFile?> Function();
typedef ReceiptReader = Future<String> Function(XFile, Uint8List);

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.pickPhoto = pickReceiptPhoto,
    this.readReceipt = recognizeReceipt,
    this.preview = false,
  });

  final PhotoPicker pickPhoto;
  final ReceiptReader readReceipt;
  final bool preview;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chrysos',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: preview ? 'packages/chrysos/ChrysosSans' : 'ChrysosSans',
      colorScheme: ColorScheme.fromSeed(seedColor: _lavender),
    ),
    home: ReceiptApp(
      pickPhoto: pickPhoto,
      readReceipt: readReceipt,
      preview: preview,
    ),
  );
}

class ReceiptApp extends StatefulWidget {
  const ReceiptApp({
    super.key,
    required this.pickPhoto,
    required this.readReceipt,
    required this.preview,
  });

  final PhotoPicker pickPhoto;
  final ReceiptReader readReceipt;
  final bool preview;

  @override
  State<ReceiptApp> createState() => _ReceiptAppState();
}

class _ReceiptAppState extends State<ReceiptApp> with TickerProviderStateMixin {
  static const _orbitPeriod = Duration(milliseconds: 570);

  late final _orbit = AnimationController(vsync: this, duration: _orbitPeriod);
  late final _merge = AnimationController(vsync: this);
  late final _animation = Listenable.merge([_orbit, _merge]);

  final _history = <({String name, String text})>[];
  XFile? _photo;
  Uint8List? _photoBytes;
  String? _result;
  String? _error;
  bool _picking = false;
  bool _scanning = false;
  bool _merging = false;
  bool _dark = true;
  bool _fullMotion = true;
  int _tab = 0;

  Color get _ink => _dark ? const Color(0xFFF7F4FC) : const Color(0xFF221D30);
  Color get _muted => _dark ? const Color(0xFFA9A4BC) : const Color(0xFF6E667A);
  Color get _surface => _dark ? const Color(0xFF1D1D2B) : Colors.white;
  Color get _line => _dark ? const Color(0xFF373245) : const Color(0xFFE4DDED);
  Color get _accent => _dark ? _lavender : const Color(0xFF6844B2);
  Color get _success => _dark ? _mint : const Color(0xFF28735B);
  bool get _reduceMotion =>
      !_fullMotion || MediaQuery.disableAnimationsOf(context);

  TextStyle _text(
    double size, {
    Color? color,
    FontWeight? weight,
    double? height,
    double? spacing,
  }) => TextStyle(
    fontSize: size,
    color: color ?? _ink,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
  );

  @override
  void dispose() {
    _orbit.dispose();
    _merge.dispose();
    super.dispose();
  }

  Future<void> _selectPhoto() async {
    if (_picking || _scanning) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final selected = await widget.pickPhoto();
      if (selected == null || !mounted) return;
      final length = await selected.length();
      if (length > _maxPhotoBytes) {
        if (mounted) setState(() => _error = 'Ukuran foto maksimal 15 MB.');
        return;
      }
      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      final jpeg =
          bytes.length > 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff;
      final png =
          bytes.length > 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47;
      if (!jpeg && !png) {
        setState(() => _error = 'Pilih foto JPG atau PNG yang bisa dibuka.');
        return;
      }
      setState(() {
        _photo = selected;
        _photoBytes = bytes;
        _result = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Foto gagal dibuka. Coba pilih foto lagi.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _startScan() async {
    final photo = _photo;
    final bytes = _photoBytes;
    if (photo == null || bytes == null || _scanning || _picking) return;
    final reduced = _reduceMotion;
    setState(() {
      _scanning = true;
      _merging = false;
      _error = null;
      _result = null;
    });
    _merge.reset();
    if (!reduced) _orbit.repeat();
    final minimumPreview = Future<void>.delayed(
      Duration(milliseconds: reduced ? 120 : 520),
    );
    try {
      final text =
          (await widget
                  .readReceipt(photo, bytes)
                  .timeout(const Duration(seconds: 50)))
              .trim();
      await minimumPreview;
      if (!mounted) return;
      if (text.isEmpty) {
        _scanFailed(
          'Teks belum terbaca. Coba foto yang lebih tajam atau terang.',
        );
        return;
      }

      _orbit.stop();
      setState(() => _merging = true);
      _merge.duration = Duration(milliseconds: reduced ? 150 : 380);
      await _merge.forward().orCancel;
      if (!mounted) return;

      setState(() {
        _result = text;
        _history.insert(0, (name: photo.name, text: text));
        _scanning = false;
        _merging = false;
      });
    } on TickerCanceled {
      // The screen was disposed while the completion animation was playing.
    } catch (_) {
      if (mounted) {
        _scanFailed('Foto gagal dipindai. Coba lagi atau pilih foto lain.');
      }
    }
  }

  void _scanFailed(String message) {
    _orbit.stop();
    setState(() {
      _scanning = false;
      _merging = false;
      _error = message;
    });
  }

  void _newSession() => setState(() {
    _photo = null;
    _photoBytes = null;
    _result = null;
    _error = null;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B0B12),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final framed = constraints.maxWidth > 600;
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(framed ? 24 : 0),
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.15, -0.5),
              radius: 1.2,
              colors: [Color(0xFF272033), Color(0xFF0B0B12)],
            ),
          ),
          child: Container(
            width: framed ? 420 : double.infinity,
            constraints: const BoxConstraints(maxHeight: 900),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(framed ? 36 : 0),
              border: framed
                  ? Border.all(color: const Color(0xFF454050))
                  : null,
              boxShadow: framed
                  ? const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 70,
                        offset: Offset(0, 24),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.1, -1),
                  radius: 1.35,
                  stops: const [0, 0.72],
                  colors: _dark
                      ? [const Color(0xFF30233F), const Color(0xFF12121B)]
                      : [const Color(0xFFEAE1FF), const Color(0xFFF6F4FA)],
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: _lavender,
                    brightness: _dark ? Brightness.dark : Brightness.light,
                  ),
                  textTheme: Theme.of(context).textTheme
                      .apply(bodyColor: _ink, displayColor: _ink),
                  iconTheme: IconThemeData(color: _ink),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: ValueKey(_tab),
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _header(),
                              const SizedBox(height: 27),
                              switch (_tab) {
                                1 => _historyPage(),
                                2 => _settingsPage(),
                                _ => _scanPage(),
                              },
                            ],
                          ),
                        ),
                      ),
                      _navigation(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _header() => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(
          _logo,
          package: widget.preview ? 'chrysos' : null,
          width: 43,
          height: 43,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
      const SizedBox(width: 10),
      Text('Chrysos', style: _text(25, weight: FontWeight.w800, spacing: -1)),
    ],
  );

  Widget _scanPage() {
    final photo = _photo;
    final result = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Pindai struk.', 'Pilih satu foto untuk memulai sesi scan.'),
        const SizedBox(height: 20),
        if (photo == null) _emptyPhoto() else _photoCard(photo, _photoBytes!),
        const SizedBox(height: 14),
        if (photo == null)
          _action(
            _picking ? 'Membuka pemilih foto…' : 'Upload gambar',
            Icons.upload_rounded,
            _picking ? null : _selectPhoto,
          )
        else if (result != null)
          _action(
            'Sesi baru',
            Icons.add_a_photo_outlined,
            _picking ? null : _newSession,
          )
        else
          _action(
            _scanning ? 'Memindai…' : 'Scan Now',
            Icons.document_scanner_outlined,
            _scanning || _picking ? null : _startScan,
          ),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: _text(
                13,
                color: _dark
                    ? const Color(0xFFFFB9C2)
                    : const Color(0xFF9C273C),
                height: 1.4,
              ),
            ),
          ),
        ],
        if (photo != null) ...[
          const SizedBox(height: 16),
          if (result != null) _resultCard(result) else _scanStatus(),
        ],
      ],
    );
  }

  Widget _emptyPhoto() => _panel(
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
    child: Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            border: Border.all(color: _accent.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            color: _accent,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        Text('Belum ada foto', style: _text(16, weight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text('JPG atau PNG · maksimal 15 MB', style: _text(12, color: _muted)),
      ],
    ),
  );

  Widget _photoCard(XFile photo, Uint8List bytes) => _panel(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 182,
            width: double.infinity,
            color: _ink.withValues(alpha: 0.045),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              cacheWidth: 720,
              semanticLabel: 'Pratinjau foto struk',
              errorBuilder: (context, error, stack) => Center(
                child: Text(
                  'Pratinjau foto gagal dimuat.',
                  style: _text(12, color: _muted),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 5),
            Icon(Icons.image_outlined, color: _accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                photo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(12, weight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: _scanning || _picking ? null : _selectPhoto,
              child: Text(
                'Ganti foto',
                style: _text(
                  12,
                  color: _scanning || _picking ? _muted : _accent,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _scanStatus() => _panel(
    child: Column(
      children: [
        if (_scanning)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => OrbitalScan(
              expansion: _reduceMotion || _merging
                  ? 1
                  : ((_orbit.lastElapsedDuration?.inMilliseconds ?? 0) / 145)
                        .clamp(0.0, 1.0),
              angle: _orbit.value * 2 * math.pi,
              completion: _merge.value,
              dark: _dark,
              reducedMotion: _reduceMotion,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Icon(
              Icons.document_scanner_outlined,
              size: 25,
              color: _accent,
            ),
          ),
        Semantics(
          liveRegion: true,
          child: Text(
            _merging
                ? 'Teks berhasil dibaca'
                : _scanning
                ? 'Membaca teks struk…'
                : 'Siap dipindai',
            style: _text(15, weight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _scanning
              ? 'Foto diproses di perangkatmu.'
              : 'Tekan Scan Now untuk mulai.',
          textAlign: TextAlign.center,
          style: _text(12, color: _muted),
        ),
      ],
    ),
  );

  Widget _resultCard(String text, {bool selectable = true}) {
    final total = receiptTotal(text);
    return _panel(
      borderColor: _success.withValues(alpha: 0.34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 31,
                width: 31,
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_rounded, color: _success, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Teks berhasil dibaca',
                  style: _text(14, color: _success, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (total != null) ...[
            const SizedBox(height: 14),
            Text('Total di struk', style: _text(12, color: _muted)),
            const SizedBox(height: 3),
            Text(
              total,
              style: _text(30, weight: FontWeight.w700, spacing: -0.8),
            ),
          ],
          const SizedBox(height: 14),
          Text('Teks struk', style: _text(12, color: _muted)),
          const SizedBox(height: 7),
          if (selectable)
            SelectableText(text, style: _text(13, height: 1.5))
          else
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _text(13, height: 1.5),
            ),
        ],
      ),
    );
  }

  Widget _historyPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'Riwayat scan',
        'Hasil yang sudah dibaca selama aplikasi ini terbuka.',
      ),
      const SizedBox(height: 20),
      if (_history.isEmpty)
        _panel(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 33, color: _accent),
              const SizedBox(height: 12),
              Text('Belum ada hasil scan.', style: _text(14, color: _muted)),
            ],
          ),
        )
      else
        for (final item in _history) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
            child: Text(item.name, style: _text(13, weight: FontWeight.w600)),
          ),
          _resultCard(item.text, selectable: false),
          const SizedBox(height: 16),
        ],
    ],
  );

  Widget _settingsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title('Pengaturan', 'Sesuaikan tema dan gerakan animasi.'),
      const SizedBox(height: 20),
      Material(
        color: _surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: _line),
        ),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              title: Text('Mode gelap', style: _text(14)),
              secondary: Icon(Icons.dark_mode_outlined, color: _accent),
              value: _dark,
              onChanged: (value) => setState(() => _dark = value),
            ),
            Divider(height: 1, color: _line),
            SwitchListTile.adaptive(
              title: Text('Animasi penuh', style: _text(14)),
              secondary: Icon(Icons.motion_photos_on_outlined, color: _accent),
              value: _fullMotion,
              onChanged: (value) => setState(() => _fullMotion = value),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _title(String title, String detail) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: _text(32, weight: FontWeight.w700, height: 1.1, spacing: -1.2),
      ),
      const SizedBox(height: 8),
      Text(detail, style: _text(13, color: _muted, height: 1.45)),
    ],
  );

  Widget _panel({
    required Widget child,
    Color? borderColor,
    EdgeInsetsGeometry padding = const EdgeInsets.all(17),
  }) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor ?? _line),
    ),
    child: child,
  );

  Widget _action(String label, IconData icon, VoidCallback? onPressed) =>
      SizedBox(
        height: 51,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEFE5FF),
            foregroundColor: const Color(0xFF342347),
            disabledBackgroundColor: _line,
            disabledForegroundColor: _muted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
        ),
      );

  Widget _navigation() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 9, 24, 18),
    child: Material(
      color: const Color(0xFFF0E6FF),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: List.generate(3, (index) {
            const labels = ['Scan', 'Riwayat', 'Atur'];
            const icons = [
              Icons.document_scanner_outlined,
              Icons.receipt_long_outlined,
              Icons.tune_rounded,
            ];
            final selected = _tab == index;
            final color = selected
                ? const Color(0xFF32204D)
                : const Color(0xFF62546F);
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _tab = index),
                  child: AnimatedContainer(
                    height: 48,
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: selected ? _lavender : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icons[index], size: 19, color: color),
                        const SizedBox(height: 3),
                        Text(
                          labels[index],
                          style: _text(
                            11,
                            color: color,
                            weight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

@Preview(name: 'Chrysos — Scan', size: Size(390, 844))
Widget chrysosPreview() => const MyApp(preview: true);

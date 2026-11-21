import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';

import 'orbital_scan.dart';

void main() => runApp(const MyApp());

const lavender = Color(0xFFAD91FF);
const mint = Color(0xFF97DCC0);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'arus. — Bukti masuk. Catatan beres.',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Arus',
      colorScheme: ColorScheme.fromSeed(seedColor: lavender),
    ),
    home: const ReceiptApp(),
  );
}

class ReceiptApp extends StatefulWidget {
  const ReceiptApp({super.key});
  @override
  State<ReceiptApp> createState() => _ReceiptAppState();
}

class _ReceiptAppState extends State<ReceiptApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan;
  bool _dark = true;
  bool _fullMotion = true;
  bool _saved = false;
  bool _hasHistory = false;
  int _tab = 0;

  Color get _ink => _dark ? const Color(0xFFF7F4FC) : const Color(0xFF221D30);
  Color get _muted => _dark ? const Color(0xFFA4A0B4) : const Color(0xFF777080);
  Color get _surface => _dark ? const Color(0xFF1D1D2B) : Colors.white;
  Color get _line => _dark ? const Color(0xFF353143) : const Color(0xFFE4DDED);
  bool get _busy => _scan.isAnimating;

  TextStyle _text(
    double size, {
    Color? color,
    FontWeight? weight,
    double? spacing,
    double? height,
  }) => TextStyle(
    fontSize: size,
    color: color ?? _ink,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
  );

  @override
  void initState() {
    super.initState();
    _scan =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 6200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _saved = true;
              _hasHistory = true;
            });
          }
        });
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  void _startScan() {
    if (_busy) return;
    setState(() => _saved = false);
    _scan.duration = Duration(
      milliseconds: _fullMotion && !MediaQuery.disableAnimationsOf(context)
          ? 6200
          : 700,
    );
    _scan.forward(from: 0);
  }

  void _reset() {
    _scan.reset();
    setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B0B12),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final framed = constraints.maxWidth > 600;
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.15, -0.5),
              radius: 1.2,
              colors: [Color(0xFF272033), Color(0xFF0B0B12)],
            ),
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.all(framed ? 24 : 0),
          child: Container(
            width: framed ? 420 : double.infinity,
            constraints: BoxConstraints(
              maxHeight: framed ? 900 : double.infinity,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(framed ? 36 : 0),
              border: framed
                  ? Border.all(color: const Color(0xFF454050))
                  : null,
              boxShadow: framed
                  ? [
                      const BoxShadow(
                        color: Colors.black45,
                        blurRadius: 70,
                        offset: Offset(0, 24),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
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
                  brightness: _dark ? Brightness.dark : Brightness.light,
                  iconTheme: IconThemeData(color: _ink),
                  textTheme: Theme.of(context).textTheme
                      .apply(bodyColor: _ink, displayColor: _ink),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _header(),
                              const SizedBox(height: 24),
                              if (_tab == 0) _scanPage(),
                              if (_tab == 1) _historyPage(),
                              if (_tab == 2) _settingsPage(),
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
      Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: const Color(0xFFF0E9FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.layers_outlined,
          color: Color(0xFF3B2B5A),
          size: 23,
        ),
      ),
      const SizedBox(width: 9),
      Text('arus', style: _text(25, weight: FontWeight.w800, spacing: -1.5)),
      const Text(
        '.',
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          color: lavender,
        ),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: _dark
              ? const Color(0xFF211F2D)
              : Colors.white.withValues(alpha: 0.6),
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: mint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('Asisten keuangan', style: _text(11, color: _muted)),
          ],
        ),
      ),
    ],
  );

  Widget _scanPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Bukti masuk.',
        style: _text(32, height: 1.1, weight: FontWeight.w700, spacing: -1.4),
      ),
      Text(
        'Catatan beres.',
        style: _text(
          32,
          height: 1.15,
          weight: FontWeight.w700,
          spacing: -1.4,
          color: lavender,
        ),
      ),
      const SizedBox(height: 22),
      _attachment(),
      const SizedBox(height: 17),
      Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: lavender.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 15,
              color: lavender,
            ),
          ),
          const SizedBox(width: 8),
          Text('ARUS ASSISTANT', style: _text(10, spacing: 0.8, color: _muted)),
          const Spacer(),
          AnimatedBuilder(
            animation: _scan,
            builder: (context, _) => AnimatedOpacity(
              opacity: _busy ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Text(
                'MEMPROSES',
                style: _text(9, spacing: 1.1, color: lavender),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      _assistantCard(),
      const SizedBox(height: 12),
      _progress(),
      const SizedBox(height: 12),
      AnimatedBuilder(
        animation: _scan,
        builder: (context, _) => _action(
          label: _saved
              ? 'Pindai lagi'
              : _busy
              ? 'Sedang membaca bukti...'
              : 'Pindai bukti ini',
          icon: _saved ? Icons.replay_rounded : Icons.document_scanner_outlined,
          onTap: _busy
              ? null
              : _saved
              ? _reset
              : _startScan,
          busy: _busy,
        ),
      ),
      const SizedBox(height: 11),
      Center(
        child: Text(
          'Demo interaktif · data contoh',
          style: _text(10, spacing: 0.15, color: _muted),
        ),
      ),
    ],
  );

  Widget _attachment() => Container(
    height: 108,
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _dark
            ? [const Color(0xFF302640), const Color(0xFF211F2F)]
            : [const Color(0xFFEBE0FC), const Color(0xFFFEFCFF)],
      ),
      border: Border.all(color: _line),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(7),
      ),
    ),
    child: Row(
      children: [
        Transform.rotate(angle: -0.13, child: ReceiptThumbnail(dark: _dark)),
        const SizedBox(width: 19),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Struk makan siang',
                style: _text(14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              Text('struk-makan.jpg · 214 KB', style: _text(11, color: _muted)),
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(Icons.image_outlined, size: 14, color: _muted),
                  const SizedBox(width: 5),
                  Text('1 gambar terlampir', style: _text(10, color: _muted)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _assistantCard() => AnimatedBuilder(
    animation: _scan,
    builder: (context, _) {
      final progress = _scan.value;
      final merging = _busy && progress > 0.70;
      final heading = merging
          ? 'Merapikan catatan'
          : progress > 0.32 && _busy
          ? 'Mengidentifikasi transaksi'
          : _busy
          ? 'Membaca bukti'
          : 'Siap membaca bukti';
      final subtitle = merging
          ? 'Semuanya sudah ketemu.'
          : progress > 0.32 && _busy
          ? 'Menentukan nominal dan kategori...'
          : _busy
          ? 'Mencari detail di dalam struk...'
          : 'Nominal, transaksi, dan kategori.';
      return AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        height: 224,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(
            color: _saved ? mint.withValues(alpha: 0.35) : _line,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(7),
            topRight: Radius.circular(30),
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _dark ? 0.12 : 0.035),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _saved
              ? _resultCard()
              : Column(
                  key: const ValueKey('scanner'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OrbitalScan(
                      progress: progress,
                      active: _busy,
                      dark: _dark,
                      reducedMotion:
                          !_fullMotion ||
                          MediaQuery.disableAnimationsOf(context),
                    ),
                    const SizedBox(height: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        heading,
                        key: ValueKey(heading),
                        style: _text(14, weight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(subtitle, style: _text(11, color: _muted)),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 8,
                      child: _busy
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final pulse = (progress * 12 - i * 0.2) % 1;
                                return Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lavender.withValues(
                                      alpha: 0.35 + pulse * 0.65,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            )
                          : null,
                    ),
                  ],
                ),
        ),
      );
    },
  );

  Widget _resultCard() => Padding(
    key: const ValueKey('result'),
    padding: const EdgeInsets.fromLTRB(23, 22, 23, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 31,
              width: 31,
              decoration: BoxDecoration(
                color: mint.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.check_rounded, color: mint, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Berhasil dicatat',
              style: _text(12, color: _dark ? mint : const Color(0xFF28735B)),
            ),
            const Spacer(),
            Icon(
              Icons.verified_outlined,
              color: _muted.withValues(alpha: 0.45),
              size: 17,
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Rp ',
                style: _text(17, color: _muted),
              ),
              TextSpan(
                text: '35.000',
                style: _text(
                  39,
                  height: 1.1,
                  weight: FontWeight.w600,
                  spacing: -1.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text('Makan Warung Bu Prapto', style: _text(13)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 5,
          children: [_tag('Pengeluaran'), _tag('Makan & minuman')],
        ),
        const Spacer(),
        Text('Minggu, 22 November 2026', style: _text(10, color: _muted)),
      ],
    ),
  );

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: _text(10, color: _muted)),
  );

  Widget _progress() => AnimatedBuilder(
    animation: _scan,
    builder: (context, _) => Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: index < 3 ? 5 : 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _line,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (_scan.value * 4 - index).clamp(0.0, 1.0),
              child: Container(color: _saved ? mint : lavender),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _action({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool busy = false,
  }) => Container(
    height: 54,
    decoration: BoxDecoration(
      color: busy
          ? (_dark ? const Color(0xFF393145) : const Color(0xFF5B506A))
          : const Color(0xFFEFE5FF),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: (_dark ? Colors.white : const Color(0xFF625078)).withValues(
            alpha: 0.16,
          ),
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const ValueKey('scan-action'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: busy ? const Color(0xFFE8DCF9) : const Color(0xFF342347),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: _text(
                    13,
                    weight: FontWeight.w600,
                    color: busy
                        ? const Color(0xFFE8DCF9)
                        : const Color(0xFF342347),
                  ),
                ),
              ),
              Icon(
                busy ? Icons.more_horiz : Icons.auto_awesome_outlined,
                size: 17,
                color: busy ? const Color(0xFFB9A9CD) : const Color(0xFF655178),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _pageTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: _text(30, weight: FontWeight.w700, spacing: -1.3)),
      const SizedBox(height: 8),
      Text(subtitle, style: _text(13, color: _muted)),
    ],
  );

  Widget _historyPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _pageTitle('Jejak transaksi.', 'Semua bukti, lebih rapi.'),
      const SizedBox(height: 26),
      if (!_hasHistory)
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.receipt_long_outlined,
                color: lavender,
                size: 38,
              ),
              const SizedBox(height: 20),
              Text(
                'Mulai dari satu bukti.',
                style: _text(16, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Pindai struk contoh dan catatanmu\nakan muncul di sini.',
                textAlign: TextAlign.center,
                style: _text(12, color: _muted, height: 1.6),
              ),
              const SizedBox(height: 25),
              _action(
                label: 'Coba pindai bukti',
                icon: Icons.document_scanner_outlined,
                onTap: () => setState(() => _tab = 0),
              ),
            ],
          ),
        )
      else ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL PENGELUARAN CONTOH',
                style: _text(10, spacing: 1, color: _muted),
              ),
              const SizedBox(height: 12),
              Text(
                'Rp 35.000',
                style: _text(29, weight: FontWeight.w600, spacing: -1),
              ),
              const SizedBox(height: 8),
              Text(
                '1 transaksi · sesi preview ini',
                style: _text(11, color: _muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text('22 NOVEMBER 2026', style: _text(10, spacing: 1, color: _muted)),
        const SizedBox(height: 14),
        Material(
          color: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _line),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 7,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lavender.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                color: lavender,
                size: 21,
              ),
            ),
            title: Text(
              'Warung Bu Prapto',
              style: _text(12, weight: FontWeight.w600),
            ),
            subtitle: Text('Makan & minuman', style: _text(10, color: _muted)),
            trailing: Text(
              '−35.000',
              style: _text(13, weight: FontWeight.w600),
            ),
            onTap: () => setState(() {
              _tab = 0;
              _saved = true;
            }),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Data contoh disimpan selama sesi preview. Pindai ulang tidak menggandakan transaksi.',
          style: _text(11, height: 1.6, color: _muted),
        ),
      ],
    ],
  );

  Widget _settingsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _pageTitle('Bikin nyaman.', 'Sedikit sentuhan, sesuai kamu.'),
      const SizedBox(height: 26),
      Material(
        color: _surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _line),
        ),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              title: Text('Mode gelap', style: _text(14)),
              subtitle: Text(
                'Lebih tenang di mata.',
                style: _text(11, color: _muted),
              ),
              secondary: const Icon(
                Icons.dark_mode_outlined,
                color: lavender,
                size: 22,
              ),
              activeTrackColor: lavender,
              value: _dark,
              onChanged: (value) => setState(() => _dark = value),
            ),
            Divider(color: _line, height: 1, indent: 18, endIndent: 18),
            SwitchListTile.adaptive(
              title: Text('Animasi penuh', style: _text(14)),
              subtitle: Text(
                'Orbital, morphing, dan success merge.',
                style: _text(10, color: _muted),
              ),
              secondary: const Icon(
                Icons.motion_photos_on_outlined,
                color: lavender,
                size: 22,
              ),
              activeTrackColor: lavender,
              value: _fullMotion,
              onChanged: (value) => setState(() => _fullMotion = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: lavender.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: lavender.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Satu bukti. Satu langkah lebih rapi.',
              style: _text(13, color: lavender, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Ini prototype interaktif dengan struk dan hasil contoh. OCR, unggah foto, dan penyimpanan permanen belum terhubung.',
              style: _text(12, height: 1.7, color: _muted),
            ),
            const SizedBox(height: 18),
            Text(
              'arus. / Chrysos · Preview 0.1',
              style: _text(10, color: _muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _navigation() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
    child: Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6FF),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Row(
        children: List.generate(3, (index) {
          const labels = ['Chat', 'Riwayat', 'Atur'];
          const icons = [
            Icons.forum_outlined,
            Icons.receipt_long_outlined,
            Icons.tune_rounded,
          ];
          final selected = _tab == index;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected ? lavender : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: lavender.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Semantics(
                  selected: selected,
                  button: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _tab = index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[index],
                            size: 19,
                            color: selected
                                ? const Color(0xFF32204D)
                                : const Color(0xFF84768F),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            style: _text(
                              10,
                              weight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? const Color(0xFF32204D)
                                  : const Color(0xFF84768F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class ReceiptThumbnail extends StatelessWidget {
  const ReceiptThumbnail({super.key, required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    width: 57,
    height: 76,
    padding: const EdgeInsets.fromLTRB(7, 10, 7, 6),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF242333) : const Color(0xFFFFFFFE),
      borderRadius: BorderRadius.circular(2),
      border: Border.all(
        color: dark ? const Color(0xFF4C435F) : const Color(0xFFE8E0EF),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(1, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BU PRAPTO',
          style: TextStyle(
            fontFamily: 'Arus',
            fontSize: 6,
            fontWeight: FontWeight.w700,
            color: dark ? const Color(0xFFF2EDF8) : const Color(0xFF302B36),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 1,
          color: dark ? const Color(0xFF60536F) : const Color(0xFFBFB7C9),
        ),
        const SizedBox(height: 3),
        Container(
          height: 1,
          width: 28,
          color: dark ? const Color(0xFF60536F) : const Color(0xFFBFB7C9),
        ),
        const SizedBox(height: 7),
        Text(
          'RP35.000',
          style: TextStyle(
            fontFamily: 'Arus',
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: dark ? const Color(0xFFF2EDF8) : const Color(0xFF302B36),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            19,
            (index) => Container(
              height: index % 3 == 0 ? 8 : 6,
              width: index % 4 == 0 ? 1.5 : 0.7,
              color: dark ? const Color(0xFF8E809E) : const Color(0xFF9E93AA),
            ),
          ),
        ),
      ],
    ),
  );
}

@Preview(name: 'Chrysos — arus. receipt scan', size: Size(390, 844))
Widget chrysosPreview() => const MyApp();

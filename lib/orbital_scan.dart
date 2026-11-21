import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// A continuous timeline: receipt tools unfold, orbit, then merge into a seal.
class OrbitalScan extends StatelessWidget {
  const OrbitalScan({
    super.key,
    required this.progress,
    required this.active,
    required this.dark,
    required this.reducedMotion,
  });
  final double progress;
  final bool active;
  final bool dark;
  final bool reducedMotion;

  double _phase(double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFFAD91FF);
    const green = Color(0xFF97DCC0);
    final expand = Curves.easeInOutCubic.transform(_phase(0, 0.17));
    final merge = Curves.easeInOutCubic.transform(_phase(0.67, 0.86));
    final seal = Curves.easeOutBack.transform(_phase(0.82, 0.96));
    final angle = reducedMotion ? 0.0 : _phase(0.06, 0.83) * math.pi * 3.2;
    const icons = [
      Icons.document_scanner_outlined,
      Icons.notes_rounded,
      Icons.receipt_long_outlined,
      Icons.trending_up_rounded,
    ];
    return Semantics(
      label: active
          ? 'Memproses struk: ikon mengorbit lalu menyatu menjadi centang sukses'
          : 'Siap memindai struk',
      image: true,
      child: SizedBox(
        height: 105,
        width: 224,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (active && !reducedMotion)
              Opacity(
                opacity: expand * (1 - merge),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        purple.withValues(alpha: 0.15),
                        purple.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            if (active)
              CustomPaint(
                size: const Size(112, 112),
                painter: _OrbitPainter(
                  rotation: angle * 0.3,
                  opacity: expand * (1 - merge),
                  color: purple,
                ),
              ),
            for (var i = 0; i < 4; i++)
              Builder(
                builder: (context) {
                  final theta = i * math.pi / 2 - math.pi / 2 + angle;
                  final radius = 38.0 * (1 - merge);
                  final rowX = (i - 1.5) * 34.0;
                  final x = active
                      ? lerpDouble(rowX, math.cos(theta) * radius, expand)! *
                            (1 - merge)
                      : rowX;
                  final y = active
                      ? math.sin(theta) * radius * expand
                      : (i.isEven ? -2.0 : 1.0);
                  final tilt = active
                      ? (reducedMotion ? 0.0 : math.sin(theta + 0.5) * 0.22) *
                            (1 - merge)
                      : (i.isEven ? -0.10 : 0.08);
                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Transform.rotate(
                      angle: tilt,
                      child: Transform.scale(
                        scale: 1 - merge * 0.52,
                        child: Opacity(
                          opacity: (1 - _phase(0.79, 0.87)).clamp(0.0, 1.0),
                          child: Container(
                            width: active ? 34 : 30,
                            height: active ? 34 : 30,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                dark
                                    ? const Color(0xFF29243D)
                                    : const Color(0xFFF6F0FF),
                                green.withValues(alpha: 0.35),
                                merge,
                              ),
                              borderRadius: BorderRadius.circular(
                                lerpDouble(10, 20, merge)!,
                              ),
                              border: Border.all(
                                color: Color.lerp(
                                  purple.withValues(alpha: 0.45),
                                  green.withValues(alpha: 0.6),
                                  merge,
                                )!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: purple.withValues(
                                    alpha: active ? 0.14 : 0.04,
                                  ),
                                  blurRadius: active ? 11 : 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              !active && i == 3
                                  ? Icons.check_rounded
                                  : icons[i],
                              size: active ? 20 : 17,
                              color: Color.lerp(purple, green, merge),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (active && progress > 0.82)
              Transform.scale(
                scale: seal,
                child: Container(
                  width: 53,
                  height: 53,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF263E36)
                        : const Color(0xFFE3F4EB),
                    borderRadius: BorderRadius.circular(
                      18 + 8 * _phase(0.82, 1),
                    ),
                    border: Border.all(color: green.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: green.withValues(alpha: 0.14),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _CheckPainter(
                      progress: _phase(0.86, 0.98),
                      color: dark ? green : const Color(0xFF34896B),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.rotation,
    required this.opacity,
    required this.color,
  });
  final double rotation;
  final double opacity;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: opacity * 0.3);
    for (var i = 0; i < 40; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 39),
        i * math.pi * 2 / 40 + rotation,
        0.065,
        false,
        paint,
      );
    }
    paint.color = color.withValues(alpha: opacity * 0.1);
    canvas.drawCircle(center, 47, paint);
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      rotation != oldDelegate.rotation ||
      opacity != oldDelegate.opacity ||
      color != oldDelegate.color;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.29, size.height * 0.51)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.73, size.height * 0.35);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * Curves.easeOut.transform(progress)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

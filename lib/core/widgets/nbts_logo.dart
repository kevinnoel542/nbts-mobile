import 'package:flutter/material.dart';

class NbtsLogo extends StatelessWidget {
  const NbtsLogo({
    super.key,
    this.size = 96,
    this.color,
    this.background,
    this.rounded = true,
  });

  final double size;
  final Color? color;
  final Color? background;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = background ?? scheme.primary;
    final fg = color ?? scheme.onPrimary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: rounded
            ? BorderRadius.circular(size * 0.22)
            : BorderRadius.zero,
      ),
      child: Center(
        child: CustomPaint(
          size: Size.square(size * 0.62),
          painter: _DropPainter(color: fg),
        ),
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  _DropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final path = Path()
      ..moveTo(cx, 0)
      ..cubicTo(cx + w * 0.10, h * 0.20, w * 0.95, h * 0.36, w * 0.95, h * 0.62)
      ..cubicTo(w * 0.95, h * 0.86, cx + w * 0.18, h, cx, h)
      ..cubicTo(cx - w * 0.18, h, w * 0.05, h * 0.86, w * 0.05, h * 0.62)
      ..cubicTo(w * 0.05, h * 0.36, cx - w * 0.10, h * 0.20, cx, 0)
      ..close();

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DropPainter oldDelegate) =>
      oldDelegate.color != color;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Logo de Dev Hub: hexágono (el "hub") con nodos en los vértices, los
/// símbolos < > de código y un nodo central dorado. Es el mismo dibujo que los
/// íconos de web/ y android/ (generados con Pillow), pero vectorial para que se
/// vea nítido en cualquier tamaño y plataforma.
class DevHubLogo extends StatelessWidget {
  final double size;

  /// Con fondo oscuro redondeado (como el ícono de la app) o sólo el trazo.
  final bool withBackground;

  const DevHubLogo({super.key, this.size = 32, this.withBackground = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo de RutaJunior',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _DevHubLogoPainter(withBackground: withBackground),
      ),
    );
  }
}

class _DevHubLogoPainter extends CustomPainter {
  final bool withBackground;
  _DevHubLogoPainter({required this.withBackground});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);

    if (withBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.22)),
        Paint()..color = AppTheme.solderMask,
      );
    }

    final r = s * 0.36;
    final vertices = [
      for (var i = 0; i < 6; i++)
        c + Offset(math.cos((-90 + 60 * i) * math.pi / 180), math.sin((-90 + 60 * i) * math.pi / 180)) * r,
    ];

    // Trazas tenues del centro a cada vértice (circuito)
    final trace = Paint()
      ..color = AppTheme.circuitTrace
      ..strokeWidth = math.max(1, s * 0.015);
    for (final v in vertices) {
      canvas.drawLine(c, v, trace);
    }

    // Hexágono
    final green = Paint()
      ..color = AppTheme.phosphorGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..addPolygon(vertices, true), green);

    // Nodos en los vértices
    final fillGreen = Paint()..color = AppTheme.phosphorGreen;
    for (final v in vertices) {
      canvas.drawCircle(v, s * 0.04, fillGreen);
    }

    // < >
    final chevron = Paint()
      ..color = AppTheme.phosphorGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cw = s * 0.095, ch = s * 0.12, gap = s * 0.075;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - gap, c.dy - ch)
        ..lineTo(c.dx - gap - cw, c.dy)
        ..lineTo(c.dx - gap, c.dy + ch),
      chevron,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + gap, c.dy - ch)
        ..lineTo(c.dx + gap + cw, c.dy)
        ..lineTo(c.dx + gap, c.dy + ch),
      chevron,
    );

    // Nodo central dorado (el hub)
    canvas.drawCircle(c, s * 0.05, Paint()..color = AppTheme.solderGold);
  }

  @override
  bool shouldRepaint(_DevHubLogoPainter oldDelegate) => oldDelegate.withBackground != withBackground;
}

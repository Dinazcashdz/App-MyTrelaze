// dart run tool/generate_icon.dart
// Génère assets/icon/app_icon.png (1024x1024) pour flutter_launcher_icons

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> main() async {
  // Render 1024×1024
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  final paint = Paint();

  // ── Fond dégradé teal→vert ────────────────────────────────────────────────
  paint.shader = ui.Gradient.linear(
    Offset.zero,
    const Offset(size, size),
    [const Color(0xFF2E5F5F), const Color(0xFF406868), const Color(0xFF5A9A6A)],
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      const Radius.circular(220),
    ),
    paint,
  );

  // ── Filigrane pin ─────────────────────────────────────────────────────────
  final pinPaint = Paint()
    ..color = const Color(0x18FFFFFF)
    ..style = PaintingStyle.fill;
  final path = Path()
    ..moveTo(size * 0.72, size * 0.20)
    ..cubicTo(size * 0.90, size * 0.20, size * 0.90, size * 0.48,
        size * 0.72, size * 0.48)
    ..cubicTo(size * 0.63, size * 0.48, size * 0.57, size * 0.55,
        size * 0.52, size * 0.62)
    ..lineTo(size * 0.46, size * 0.80)
    ..lineTo(size * 0.40, size * 0.62)
    ..cubicTo(size * 0.35, size * 0.55, size * 0.29, size * 0.48,
        size * 0.20, size * 0.48)
    ..cubicTo(size * 0.02, size * 0.48, size * 0.02, size * 0.20,
        size * 0.20, size * 0.20)
    ..close();
  canvas.drawPath(path, pinPaint);

  // ── Texte "MT" ────────────────────────────────────────────────────────────
  final mtParagraph = _buildParagraph(
    'MT',
    fontSize: size * 0.30,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -size * 0.012,
  );
  mtParagraph.layout(const ui.ParagraphConstraints(width: size));
  canvas.drawParagraph(
    mtParagraph,
    Offset((size - mtParagraph.longestLine) / 2, size * 0.31),
  );

  // ── Ligne séparatrice ─────────────────────────────────────────────────────
  final linePaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset(size * 0.31, 0),
      Offset(size * 0.69, 0),
      [const Color(0x44FFFFFF), Colors.white, const Color(0x44FFFFFF)],
    )
    ..strokeWidth = size * 0.015
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    Offset(size * 0.31, size * 0.635),
    Offset(size * 0.69, size * 0.635),
    linePaint,
  );

  // ── Texte "My Trélazé" ────────────────────────────────────────────────────
  final subParagraph = _buildParagraph(
    'My Trélazé',
    fontSize: size * 0.082,
    fontWeight: FontWeight.w600,
    color: const Color(0xCCFFFFFF),
    letterSpacing: size * 0.003,
  );
  subParagraph.layout(const ui.ParagraphConstraints(width: size));
  canvas.drawParagraph(
    subParagraph,
    Offset((size - subParagraph.longestLine) / 2, size * 0.67),
  );

  // ── Export PNG ────────────────────────────────────────────────────────────
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) throw Exception('toByteData returned null');

  final file = File('assets/icon/app_icon.png');
  await file.writeAsBytes(bytes.buffer.asUint8List());
  stdout.writeln('✅  assets/icon/app_icon.png généré (${file.lengthSync()} bytes)');

  // Foreground identique (pour adaptive icon — même image sans fond)
  final fgFile = File('assets/icon/app_icon_foreground.png');
  await fgFile.writeAsBytes(bytes.buffer.asUint8List());
  stdout.writeln('✅  assets/icon/app_icon_foreground.png généré');
}

ui.Paragraph _buildParagraph(
  String text, {
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double letterSpacing = 0,
}) {
  final style = ui.ParagraphStyle(
    textAlign: TextAlign.center,
  );
  final builder = ui.ParagraphBuilder(style)
    ..pushStyle(ui.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    ))
    ..addText(text);
  return builder.build();
}

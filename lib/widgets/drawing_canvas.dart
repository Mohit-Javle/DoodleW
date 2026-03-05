import 'dart:math';
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';

class DrawingCanvas extends StatelessWidget {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final GlobalKey canvasKey;
  final double width;
  final double height;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    this.currentStroke,
    required this.canvasKey,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
            ),
          ],
        ),
        child: RepaintBoundary(
          key: canvasKey,
          child: Stack(
            children: [
              // Layer 1: All finished strokes. RepaintBoundary caches this heavily!
              RepaintBoundary(
                child: CustomPaint(
                  painter: CanvasPainter(
                    strokes: strokes,
                    isFinishedLayer: true,
                  ),
                  size: Size(width, height),
                ),
              ),
              // Layer 2: Only the active stroke. Redraws at 60fps without lagging the background.
              CustomPaint(
                painter: CanvasPainter(
                  currentStroke: currentStroke,
                  isFinishedLayer: false,
                ),
                size: Size(width, height),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke>? strokes;
  final DrawingStroke? currentStroke;
  final bool isFinishedLayer;

  CanvasPainter({
    this.strokes,
    this.currentStroke,
    required this.isFinishedLayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isFinishedLayer) {
      // Background must be white for blending
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Offset.zero & size, bgPaint);

      if (strokes != null && strokes!.isNotEmpty) {
        // saveLayer allows BlendMode.clear to work purely on this canvas bounds
        canvas.saveLayer(Offset.zero & size, Paint());
        for (final stroke in strokes!) {
          _drawStroke(canvas, stroke);
        }
        canvas.restore();
      }
    } else {
      if (currentStroke != null) {
        // We do NOT use saveLayer here to avoid performance hit on active stroke.
        // However, if it's an eraser, we just draw a white line on top for the preview.
        _drawStroke(canvas, currentStroke!, isActiveLayer: true);
      }
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke, {bool isActiveLayer = false}) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.brushType == BrushType.eraser) {
      if (isActiveLayer) {
        // Just draw a white stroke to simulate erasing over the background
        paint.color = Colors.white;
        paint.blendMode = BlendMode.srcOver;
      } else {
        // Actually clear the finished layer
        paint.blendMode = BlendMode.clear;
        paint.color = const Color(0x00000000); // Color doesn't matter for clear
      }
    }

    switch (stroke.brushType) {
      case BrushType.normal:
        _drawStandardPath(canvas, stroke.points, paint);
        break;
      case BrushType.marker:
        paint.color = paint.color.withValues(alpha: 0.4);
        paint.strokeWidth = stroke.strokeWidth * 1.5;
        _drawStandardPath(canvas, stroke.points, paint);
        break;
      case BrushType.neon:
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        _drawStandardPath(canvas, stroke.points, paint);
        final corePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = stroke.strokeWidth * 0.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
        _drawStandardPath(canvas, stroke.points, corePaint);
        break;
      case BrushType.spray:
        _drawSprayEffect(canvas, stroke.points, paint, isActiveLayer);
        break;
      case BrushType.calligraphy:
        _drawCalligraphy(canvas, stroke.points, paint.color, stroke.strokeWidth);
        break;
      case BrushType.eraser:
        _drawStandardPath(canvas, stroke.points, paint);
        if (isActiveLayer) {
          // Draw a faint grey border around the active eraser for visibility
          final borderPaint = Paint()
            ..color = Colors.grey.withValues(alpha: 0.5)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;
          _drawStandardPath(canvas, stroke.points, borderPaint);
        }
        break;
    }
  }

  void _drawStandardPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawSprayEffect(Canvas canvas, List<Offset> points, Paint paint, bool isActiveLayer) {
    // Seed the random generator if it's the finished layer to prevent jittering on repaints.
    final random = isActiveLayer ? Random() : Random(42); 
    final sprayPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      // Density reduction: less particles drawn per point saves immense performance
      for (int i = 0; i < 3; i++) {
        final double radius = paint.strokeWidth * 1.2;
        final double angle = random.nextDouble() * 2 * pi;
        final double distance = random.nextDouble() * radius;
        final double dx = point.dx + distance * cos(angle);
        final double dy = point.dy + distance * sin(angle);
        canvas.drawCircle(Offset(dx, dy), 1.0, sprayPaint);
      }
    }
  }

  void _drawCalligraphy(Canvas canvas, List<Offset> points, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(pi / 4);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: width, height: width * 0.3), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    if (isFinishedLayer) {
      // Only repaint background if strokes list changed exactly
      return oldDelegate.strokes != strokes;
    } else {
      // Always repaint active layer when drawing because we mutate the points array
      // directly for maximum performance, so the object reference doesn't change!
      return true;
    }
  }
}

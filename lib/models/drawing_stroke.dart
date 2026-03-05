import 'package:flutter/material.dart';

enum BrushType {
  normal,
  marker,
  neon,
  spray,
  calligraphy,
  eraser,
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final BrushType brushType;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.brushType,
  });

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    BrushType? brushType,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      brushType: brushType ?? this.brushType,
    );
  }
}

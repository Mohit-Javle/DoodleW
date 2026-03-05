import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';

class BrushSelector extends StatelessWidget {
  final BrushType selectedType;
  final double strokeWidth;
  final ValueChanged<BrushType> onTypeChanged;
  final ValueChanged<double> onWidthChanged;

  const BrushSelector({
    super.key,
    required this.selectedType,
    required this.strokeWidth,
    required this.onTypeChanged,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: BrushType.values.where((e) => e != BrushType.eraser).map((type) {
            return IconButton(
              icon: Icon(_getIconForType(type)),
              color: selectedType == type ? Theme.of(context).colorScheme.primary : Colors.white60,
              onPressed: () => onTypeChanged(type),
              tooltip: type.name.toUpperCase(),
            );
          }).toList(),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Icon(Icons.line_weight, size: 16),
              Expanded(
                child: Slider(
                  value: strokeWidth,
                  min: 1.0,
                  max: 40.0,
                  onChanged: onWidthChanged,
                ),
              ),
              Text(strokeWidth.toInt().toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(BrushType type) {
    switch (type) {
      case BrushType.normal: return Icons.gesture;
      case BrushType.marker: return Icons.brush;
      case BrushType.neon: return Icons.wb_sunny_outlined;
      case BrushType.spray: return Icons.blur_on;
      case BrushType.calligraphy: return Icons.history_edu;
      case BrushType.eraser: return Icons.cleaning_services;
    }
  }
}

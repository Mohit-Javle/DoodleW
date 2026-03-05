import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPalette extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  static const List<Color> paletteColors = [
    Colors.black, Colors.white, Colors.red, Colors.pink, Colors.purple,
    Colors.deepPurple, Colors.indigo, Colors.blue, Colors.lightBlue,
    Colors.cyan, Colors.teal, Colors.green, Colors.lightGreen,
    Colors.lime, Colors.yellow, Colors.amber, Colors.orange,
    Colors.deepOrange, Colors.brown, Colors.grey, Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: paletteColors.length + 1,
        itemBuilder: (context, index) {
          if (index == paletteColors.length) {
            // Custom color picker button
            return IconButton(
              icon: const Icon(Icons.colorize),
              onPressed: () => _showColorPicker(context),
            );
          }
          final color = paletteColors[index];
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              width: 30,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedColor == color ? Colors.white : Colors.white24,
                  width: selectedColor == color ? 3 : 1,
                ),
                boxShadow: [
                  if (selectedColor == color)
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: onColorChanged,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

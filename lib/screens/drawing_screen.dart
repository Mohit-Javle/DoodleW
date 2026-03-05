import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/brush_selector.dart';
import '../widgets/color_palette.dart';
import '../utils/image_utils.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  
  List<DrawingStroke> _strokes = [];
  List<DrawingStroke> _redoStrokes = [];
  
  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;
  BrushType _selectedBrush = BrushType.normal;
  bool _isEraserMode = false;
  bool _isNavMode = false; // Hand tool for panning/zooming

  DrawingStroke? _currentStroke;

  // Constants for fixed canvas size - large for high quality
  final double _canvasWidth = 1200;
  final double _canvasHeight = 1800;

  // The InteractiveViewer automatically transforms pointer events for its children,
  // so `details.localPosition` from the GestureDetector already gives us the 
  // exact coordinates on the canvas itself! No manual matrix inversion needed.

  void _onPanStart(DragStartDetails details) {
    if (_isNavMode) return;
    
    final canvasOffset = details.localPosition;
    // Boundary check
    if (canvasOffset.dx < 0 || canvasOffset.dx > _canvasWidth || 
        canvasOffset.dy < 0 || canvasOffset.dy > _canvasHeight) {
      return;
    }

    setState(() {
      _currentStroke = DrawingStroke(
        points: [canvasOffset],
        color: _isEraserMode ? Colors.transparent : _selectedColor,
        strokeWidth: _strokeWidth,
        brushType: _isEraserMode ? BrushType.eraser : _selectedBrush,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isNavMode) return;
    if (_currentStroke == null) return;
    
    final canvasOffset = details.localPosition;
    
    setState(() {
      _currentStroke!.points.add(canvasOffset);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isNavMode) return;
    if (_currentStroke == null) return;
    setState(() {
      _strokes = List.from(_strokes)..add(_currentStroke!);
      _currentStroke = null;
      _redoStrokes = [];
    });
  }

  void _undo() {
    if (_strokes.isEmpty) {
      return;
    }
    setState(() {
      final stroke = _strokes.last;
      _strokes = List.from(_strokes)..removeLast();
      _redoStrokes = List.from(_redoStrokes)..add(stroke);
    });
  }

  void _redo() {
    if (_redoStrokes.isEmpty) {
      return;
    }
    setState(() {
      final stroke = _redoStrokes.last;
      _redoStrokes = List.from(_redoStrokes)..removeLast();
      _strokes = List.from(_strokes)..add(stroke);
    });
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas?'),
        content: const Text('This will delete all your beautiful doodles.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                _strokes = [];
                _redoStrokes = [];
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canvas is empty! Draw something first.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading your doodle...'), duration: Duration(seconds: 1)),
    );

    final success = await ImageUtils.saveCanvasToGallery(_canvasKey);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Doodle saved to gallery! 🎉' : 'Failed to save doodle. Please check permissions. 😕'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the editor
      appBar: AppBar(
        title: const Text('Doodle'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(icon: const Icon(Icons.redo), onPressed: _redo),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearCanvas),
          IconButton(icon: const Icon(Icons.download), onPressed: _saveImage),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.1,
              maxScale: 10.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Padding(
                padding: const EdgeInsets.all(100.0), // Give some space to see the paper edges
                child: GestureDetector(
                  // Only enable drawing gestures if NOT in nav mode
                  onPanStart: _isNavMode ? null : _onPanStart,
                  onPanUpdate: _isNavMode ? null : _onPanUpdate,
                  onPanEnd: _isNavMode ? null : _onPanEnd,
                  child: DrawingCanvas(
                    canvasKey: _canvasKey,
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    width: _canvasWidth,
                    height: _canvasHeight,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 24, top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, -2))
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPalette(
                  selectedColor: _selectedColor,
                  onColorChanged: (color) => setState(() {
                    _selectedColor = color;
                    if (_isEraserMode || _isNavMode) {
                      _isEraserMode = false;
                      _isNavMode = false;
                    }
                  }),
                ),
                const Divider(height: 1, color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_isNavMode ? Icons.pan_tool : Icons.pan_tool_outlined),
                        color: _isNavMode ? Theme.of(context).colorScheme.primary : Colors.white60,
                        onPressed: () => setState(() {
                           _isNavMode = true;
                           _isEraserMode = false;
                        }),
                        tooltip: 'Pan & Zoom',
                      ),
                      IconButton(
                        icon: Icon(_isEraserMode ? Icons.cleaning_services : Icons.cleaning_services_outlined),
                        color: _isEraserMode ? Theme.of(context).colorScheme.primary : Colors.white60,
                        onPressed: () => setState(() {
                            _isEraserMode = true;
                            _isNavMode = false;
                        }),
                        tooltip: 'Eraser',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BrushSelector(
                          selectedType: _selectedBrush,
                          strokeWidth: _strokeWidth,
                          onTypeChanged: (type) => setState(() {
                            _selectedBrush = type;
                            _isEraserMode = false;
                            _isNavMode = false;
                          }),
                          onWidthChanged: (width) => setState(() => _strokeWidth = width),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

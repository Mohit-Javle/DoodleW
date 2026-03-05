import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:io';

class ImageUtils {
  static Future<bool> saveCanvasToGallery(GlobalKey boundaryKey) async {
    try {
      // Permission Handling
      if (Platform.isAndroid) {
         // Try requesting all relevant permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.photos,
        ].request();
        
        // Android 13+ check
        if (statuses[Permission.photos] != PermissionStatus.granted && 
            statuses[Permission.storage] != PermissionStatus.granted) {
          // Fallback check for Android 13+ which might use separate permissions
          if (!(await Permission.photos.isGranted)) {
             debugPrint("Permissions denied");
             return false;
          }
        }
      } else {
        if (!(await Permission.photos.request().isGranted)) {
          return false;
        }
      }

      RenderRepaintBoundary? boundary =
            boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        
      if (boundary == null) {
        debugPrint("Boundary is null");
        return false;
      }

      // Capture with higher pixel ratio for quality
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List bytes = byteData.buffer.asUint8List();
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 95,
          name: "doodle_${DateTime.now().millisecondsSinceEpoch}",
        );
        
        debugPrint("Save result: $result");
        // Handle result being a String (path) or Map
        if (result is Map) {
          return result['isSuccess'] == true || result['isSuccess'] == "true";
        } else if (result is String && result.isNotEmpty) {
          return true; // Path returned means success
        }
        return false;
      }
      return false;
    } catch (e) {
      debugPrint("Error saving image: $e");
      return false;
    }
  }
}

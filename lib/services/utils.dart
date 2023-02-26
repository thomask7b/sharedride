import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> iconToBitmapDescriptor(IconData iconData) async {
  final pictureRecorder = PictureRecorder();
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        letterSpacing: 0.0,
        fontSize: 48.0,
        fontFamily: iconData.fontFamily,
        color: Colors.black87,
      ));
  textPainter.layout();
  textPainter.paint(Canvas(pictureRecorder), const Offset(0.0, 0.0));
  final image = await pictureRecorder.endRecording().toImage(48, 48);
  final bytes = await image.toByteData(format: ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

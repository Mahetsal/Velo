import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Simple car silhouette for nearby drivers — no personal data, only a generic icon.
Future<BitmapDescriptor> createCarMarkerBitmapDescriptor() async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(size / 2, size / 2 + 2);

  // Soft shadow
  canvas.drawCircle(
    center.translate(0, 2),
    26,
    Paint()..color = const Color(0x40000000),
  );

  // Body
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: center.translate(0, -4), width: 56, height: 34),
    const Radius.circular(10),
  );
  canvas.drawRRect(body, Paint()..color = const Color(0xFF2563EB));

  // Roof / windshield
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, -10), width: 40, height: 18),
      const Radius.circular(6),
    ),
    Paint()..color = const Color(0xFF93C5FD),
  );

  // Wheels
  final wheel = Paint()..color = const Color(0xFF0F172A);
  canvas.drawCircle(center.translate(-18, 14), 8, wheel);
  canvas.drawCircle(center.translate(18, 14), 8, wheel);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }
  return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location.dart';
import '../models/sharedride.dart';

const zoomLevel = 15.0;
const highSpeedZoomLevel = 14.0;

class MapService {
  final GoogleMapController _controller;
  final SharedRide _sharedRide;

  MapService(this._controller, this._sharedRide) {
    fitOnSharedRide();
  }

  void fitOnSharedRide() {
    fitMapOnBounds(geoCoordBoundsToLatLngBounds(
        _sharedRide.direction.routes!.first.bounds!));
  }

  void fitMapOnBounds(LatLngBounds bounds) {
    _controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void updateCamera(LatLng latLng,
      {double bearing = 0, bool highSpeed = false}) {
    _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: latLng,
        bearing: bearing,
        zoom: highSpeed ? highSpeedZoomLevel : zoomLevel)));
  }
}

final PolylinePoints _polylineUtils = PolylinePoints();

List<LatLng> decodePolylines(SharedRide sharedRide) {
  return sharedRide.direction.routes!.first.legs!
      .expand((leg) => leg.steps!.expand((step) => _polylineUtils
          .decodePolyline(step.polyline!.points!)
          .map((ptLatLng) => LatLng(ptLatLng.latitude, ptLatLng.longitude))))
      .toList();
}

LatLngBounds geoCoordBoundsToLatLngBounds(GeoCoordBounds bounds) {
  return LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
      northeast: LatLng(bounds.northeast.latitude, bounds.northeast.longitude));
}

LatLng centerOfGeoCoordBounds(GeoCoordBounds bounds) {
  return LatLng(
    (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
    (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
  );
}

LatLng geoCoordToLatLng(GeoCoord geoCoord) {
  return LatLng(geoCoord.latitude, geoCoord.longitude);
}

LatLng locationToLatLng(Location location) =>
    LatLng(location.latitude, location.longitude);

LatLng positionToLatLng(Position position) =>
    LatLng(position.latitude, position.longitude);

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

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/sharedride.dart';

enum MODE { tracking, overview }

class MapService {
  final GoogleMapController _controller;
  final SharedRide _sharedRide;

  MapService(this._controller, this._sharedRide) {
    fitMapOnBounds(geoCoordBoundsToLatLngBounds(
        _sharedRide.direction.routes!.first.bounds!));
  }

  void fitMapOnBounds(LatLngBounds bounds) {
    _controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void updateCamera(LatLng latLng, {double bearing = 0}) {
    _controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, bearing: bearing)));
  }
}

final PolylinePoints _polylineUtils = PolylinePoints();

List<LatLng> decodePolylines(SharedRide sharedRide) {
  return sharedRide.direction.routes!.first.legs!.first.steps!
      .expand((step) => _polylineUtils
          .decodePolyline(step.polyline!.points!)
          .map((ptLatLng) => LatLng(ptLatLng.latitude, ptLatLng.longitude)))
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

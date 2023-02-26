import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location.dart';
import '../models/sharedride.dart';
import 'location_service.dart';

class MapService {
  final GoogleMapController _controller;
  final SharedRide _sharedRide;
  late final List<Step> _steps;
  var _actualStep = 0;
  var _isOnRide = false;

  List<Step> get steps => _steps;

  int get actualStep => _actualStep;

  bool get isOnRide => _isOnRide;

  String get instructions => _steps.elementAt(_actualStep + 1).instructions!;

  int get distanceBetweenSteps =>
      _steps.elementAt(_actualStep).distance!.value!.round();

  MapService(this._controller, this._sharedRide) {
    fitOnSharedRide();
    _steps = _sharedRide.direction.routes!.first.legs!
        .expand((leg) => leg.steps!)
        .toList();
  }

  void fitOnSharedRide() {
    fitMapOnBounds(geoCoordBoundsToLatLngBounds(
        _sharedRide.direction.routes!.first.bounds!));
  }

  void fitMapOnBounds(LatLngBounds bounds) {
    _controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void updateCamera(LatLng latLng,
      {double bearing = 0, ZoomLevel zoomLevel = ZoomLevel.normal}) {
    _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: latLng, bearing: bearing, zoom: zoomLevel.value)));
  }

  void updateSituation(Location location) {
    if (!_isOnRide) {
      for (var i = 0; i < _steps.length; i++) {
        if (_isOnStep(_steps[i], location)) {
          _actualStep = i;
          break;
        }
      }
    }
    if (_isOnStep(_steps.elementAt(_actualStep), location)) {
      _isOnRide = true;
    } else {
      if (_isOnStep(_steps.elementAt(_actualStep + 1), location)) {
        _isOnRide = true;
        _actualStep++;
      } else {
        _isOnRide = false;
      }
    }
  }

  int distanceToNextStep(Location location) {
    return distanceBetween(location,
            geoCoordToLocation(_steps.elementAt(_actualStep).endLocation!))
        .round();
  }

  bool _isOnStep(Step step, Location location) {
    return _polylineUtils.decodePolyline(step.polyline!.points!).any((p) =>
        distanceBetween(Location(p.latitude, p.longitude), location) < 25);
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

Location geoCoordToLocation(GeoCoord geoCoord) {
  return Location(geoCoord.latitude, geoCoord.longitude);
}

LatLng locationToLatLng(Location location) =>
    LatLng(location.latitude, location.longitude);

LatLng positionToLatLng(Position position) =>
    LatLng(position.latitude, position.longitude);

Location positionToLocation(Position position) =>
    Location(position.latitude, position.longitude);

enum ZoomLevel { veryHigh, high, normal, low, veryLow }

extension ZoomLevelValue on ZoomLevel {
  static const zoomLevels = {
    ZoomLevel.veryHigh: 14.0,
    ZoomLevel.high: 15.0,
    ZoomLevel.normal: 16.0,
    ZoomLevel.low: 17.0,
    ZoomLevel.veryLow: 18.0,
  };

  double get value => zoomLevels[this]!;
}

ZoomLevel zoomLevelFromSpeed(double speed) {
  if (speed > 150) {
    return ZoomLevel.veryHigh;
  } else if (speed > 100) {
    return ZoomLevel.high;
  } else if (speed > 50) {
    return ZoomLevel.normal;
  } else if (speed > 25) {
    return ZoomLevel.low;
  } else {
    return ZoomLevel.veryLow;
  }
}

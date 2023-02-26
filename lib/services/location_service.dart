import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:sharedride/models/location.dart';

const LocationSettings _locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 5,
);

Stream<Position> positionStream() {
  return Geolocator.getPositionStream(locationSettings: _locationSettings);
}

Future<Position> initLocationService() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Permission refusée.');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return Future.error("Permission refusée de manière permanente.");
  }

  return await Geolocator.getCurrentPosition();
}

double distanceBetween(Location firstLocation, Location secondLocation) {
  return Geolocator.distanceBetween(
      firstLocation.latitude,
      firstLocation.longitude,
      secondLocation.latitude,
      secondLocation.longitude);
}

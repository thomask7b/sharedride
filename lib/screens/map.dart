import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sharedride/models/sharedride.dart';
import 'package:sharedride/screens/login.dart';
import 'package:sharedride/screens/sharedride.dart';
import 'package:sharedride/services/auth_service.dart';
import 'package:sharedride/services/geo_service.dart';
import 'package:sharedride/services/location_service.dart';
import 'package:sharedride/services/sharedride_service.dart';
import 'package:sharedride/services/stomp_service.dart';

import '../config.dart';
import '../models/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Future<SharedRide?> _sharedRide = getSharedRide(actualSharedRideId!);
  bool _isTracking = false;
  int _displayedSpeed = 0;

  late final MapService _mapService;
  late Position _currentPosition;
  late Timer trackingModeTimer;

  static const MarkerId _currentLocationMarkerId = MarkerId("currentLocation");
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    startEmitClient();
    initLocationService().then((initPosition) {
      _currentPosition = initPosition;
      _initMarker(_currentLocationMarkerId, positionToLatLng(initPosition),
              Icons.my_location)
          .then((_) {
        positionStream().listen((streamPosition) {
          _currentPosition = streamPosition;
          sendStompLocation(actualSharedRideId!.hexString,
              Location(streamPosition.latitude, streamPosition.longitude));
          _updateMarker(
              _currentLocationMarkerId, positionToLatLng(_currentPosition));
          _fitMap();
          setState(() {
            _displayedSpeed = _currentPosition.speed.round();
          });
        });
        startReceiveClient((userLocation) {
          if (userLocation.key != authenticatedUser!.name) {
            _updateMarker(MarkerId(userLocation.key),
                locationToLatLng(userLocation.value));
          }
        }); //TODO update shared ride
      });
    });
  }

  @override
  void dispose() {
    stopReceiveClient();
    stopEmitClient();
    super.dispose();
  }

  Future<void> _initMarker(
      MarkerId id, LatLng latLng, IconData iconData) async {
    await iconToBitmapDescriptor(iconData).then((icon) {
      setState(() {
        _markers.add(Marker(markerId: id, position: latLng, icon: icon));
      });
    });
  }

  void _updateMarker(MarkerId id, LatLng latLng) {
    if (_markers.any((m) => m.markerId == id)) {
      final marker = _markers.firstWhere((m) => m.markerId == id);
      setState(() {
        _markers.remove(marker);
        _markers.add(Marker(markerId: id, position: latLng, icon: marker.icon));
      });
    } else {
      _initMarker(id, latLng, Icons.share_location);
    }
  }

  void _fitMap() {
    if (_isTracking) {
      _mapService.updateCamera(
          LatLng(_currentPosition.latitude, _currentPosition.longitude),
          bearing: _currentPosition.heading,
          highSpeed: _currentPosition.speed > 100);
    } else {
      _mapService.fitOnSharedRide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            return [
              const PopupMenuItem<int>(
                value: 0,
                child: Text("Quitter le shared ride"),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Text("Déconnexion"),
              ),
            ];
          }, onSelected: (value) {
            switch (value) {
              case 0:
                stopReceiveClient();
                stopEmitClient();
                exitSharedRide().then((value) => Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(
                        builder: (context) => const SharedRideScreen())));
                break;
              case 1:
                stopReceiveClient();
                stopEmitClient();
                logout().then((value) => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const LoginFormScreen())));
                break;
            }
          }),
        ],
      ),
      body: FutureBuilder<SharedRide?>(
          future: _sharedRide,
          builder: (BuildContext context, AsyncSnapshot<SharedRide?> snapshot) {
            if (snapshot.hasData) {
              return _buildMap(snapshot.data!);
            } else if (snapshot.hasError) {
              return Column(children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                ),
              ]);
            } else {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                    CircularProgressIndicator(),
                    Text("Chargement du shared ride...")
                  ]));
            }
          }),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () => _displayMode(),
          child: _isTracking
              ? const Icon(Icons.gps_not_fixed)
              : const Icon(Icons.gps_fixed)),
    );
  }

  void _displayMode() {
    setState(() {
      _isTracking = !_isTracking;
    });
    _fitMap();
  }

  Widget _buildMap(SharedRide sharedRide) {
    final startLocation = geoCoordToLatLng(
        sharedRide.direction.routes!.first.legs!.first.startLocation!);
    final initialCameraPosition = CameraPosition(
      target: startLocation,
      zoom: zoomLevel,
    );

    return Stack(children: <Widget>[
      GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialCameraPosition,
        zoomControlsEnabled: false,
        zoomGesturesEnabled: true,
        rotateGesturesEnabled: false,
        scrollGesturesEnabled: true,
        polylines: {
          Polyline(
              polylineId: const PolylineId("ride"),
              points: decodePolylines(sharedRide),
              color: Colors.blue,
              width: 6)
        },
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _mapService = MapService(controller, sharedRide);
          //TODO si des positions existent déjà dans le shared ride il faut les afficher
        },
      ),
      Align(alignment: Alignment.topCenter, child: _buildSteps(sharedRide)),
      Align(alignment: Alignment.bottomLeft, child: _buildSpeed()),
    ]);
  }

  Widget _buildSteps(SharedRide sharedRide) {
    final legs = sharedRide.direction.routes!.first.legs!;
    final startAddress = legs.first.startAddress!;
    final endAddress = legs.last.endAddress!;
    return Container(
      height: 40,
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(5.0),
      decoration: _stepsDecoration(),
      child: Text(
        overflow: TextOverflow.ellipsis,
        "$startAddress > $endAddress",
        style: const TextStyle(fontSize: 20.0),
      ),
    );
  }

  Widget _buildSpeed() {
    return Container(
      height: 40,
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(5.0),
      decoration: _stepsDecoration(),
      child: Text(
        "$_displayedSpeed km/h",
        style: const TextStyle(fontSize: 20.0),
      ),
    );
  }

  BoxDecoration _stepsDecoration() {
    return BoxDecoration(
      color: Colors.blue.shade100,
      boxShadow: [
        BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3)),
      ],
      border: Border(
          left: BorderSide(
            color: Colors.blue.shade100,
            width: 5,
          ),
          top: BorderSide(
            color: Colors.blue.shade300,
            width: 3,
          ),
          right: BorderSide(color: Colors.blue.shade500, width: 2),
          bottom: BorderSide(color: Colors.blue.shade800, width: 2)),
    );
  }
}

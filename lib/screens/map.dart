import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
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
import '../services/utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum ActionMenu { quit, logout, copySharedRideId }

class _MapScreenState extends State<MapScreen> {
  final Future<SharedRide?> _sharedRide = getSharedRide(actualSharedRideId!);

  late final MapService _mapService;
  late Position _currentPosition;

  static const String _defaultInstructions = "<b>Rejoignez l'itinéraire</b>";
  static const MarkerId _currentLocationMarkerId = MarkerId("currentLocation");
  final Set<Marker> _markers = {};

  bool _isTracking = false;
  int _displayedSpeed = 0;
  String _instructions = _defaultInstructions;
  String _distanceToNextStep = "0 m";

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
              positionToLocation(streamPosition));
          _updateMarker(
              _currentLocationMarkerId, positionToLatLng(_currentPosition));
          _fitMap();
          _mapService.updateSituation(positionToLocation(_currentPosition));
          setState(() {
            _displayedSpeed = _currentPosition.speed.round();
            _instructions = _mapService.isOnRide
                ? _mapService.instructions
                : _defaultInstructions;
            _distanceToNextStep = _formatDitanceToNextStep(_mapService
                .distanceToNextStep(positionToLocation(_currentPosition)));
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
          zoomLevel: zoomLevelFromSpeed(_currentPosition.speed));
    } else {
      _mapService.fitOnSharedRide();
    }
  }

  String _formatDitanceToNextStep(int distanceInMeters) {
    if (distanceInMeters > 1000) {
      final distanceInKiloMeters = (distanceInMeters / 1000).toStringAsFixed(1);
      return "$distanceInKiloMeters km";
    }
    return "${(distanceInMeters / 10).round() * 10} m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            return [
              const PopupMenuItem<ActionMenu>(
                value: ActionMenu.copySharedRideId,
                child: Text("Copier l'ID du shared ride"),
              ),
              const PopupMenuItem<ActionMenu>(
                value: ActionMenu.quit,
                child: Text("Quitter le shared ride"),
              ),
              const PopupMenuItem<ActionMenu>(
                value: ActionMenu.logout,
                child: Text("Déconnexion"),
              ),
            ];
          }, onSelected: (value) {
            switch (value) {
              case ActionMenu.copySharedRideId:
                Clipboard.setData(
                        ClipboardData(text: actualSharedRideId!.hexString))
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("L'ID du shared ride a bien été copié.")));
                });
                break;
              case ActionMenu.quit:
                stopReceiveClient();
                stopEmitClient();
                exitSharedRide().then((value) => Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(
                        builder: (context) => const SharedRideScreen())));
                break;
              case ActionMenu.logout:
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
      zoom: ZoomLevel.normal.value,
    );

    return Stack(children: <Widget>[
      GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialCameraPosition,
        zoomControlsEnabled: false,
        zoomGesturesEnabled: true,
        rotateGesturesEnabled: false,
        scrollGesturesEnabled: true,
        buildingsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
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
      Align(alignment: Alignment.topCenter, child: _buildInstructions()),
      Align(alignment: Alignment.bottomLeft, child: _buildSpeed()),
      Align(
          alignment: Alignment.bottomCenter, child: _buildDistanceToNextStep()),
    ]);
  }

  Widget _buildSteps(SharedRide sharedRide) {
    final legs = sharedRide.direction.routes!.first.legs!;
    final startAddress = legs.first.startAddress!;
    final endAddress = legs.last.endAddress!;
    return _container(
      Text(
        overflow: TextOverflow.ellipsis,
        "$startAddress > $endAddress",
        style: const TextStyle(fontSize: 18.0),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10.0, 50, 10.0, 10.0),
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
          boxShadow: _boxShadow(),
          gradient: LinearGradient(
              stops: const [0.02, 0.02],
              colors: _instructions == _defaultInstructions
                  ? [Colors.red.shade800, Colors.red.shade200.withOpacity(0.6)]
                  : [
                      Colors.blue.withOpacity(0.6),
                      Colors.white.withOpacity(0.6)
                    ]),
          borderRadius: const BorderRadius.all(Radius.circular(6.0))),
      child: Html(
        style: {
          'html': Style(textAlign: TextAlign.center),
        },
        data: _instructions,
      ),
    );
  }

  Widget _buildSpeed() {
    return _container(
      Text(
        "$_displayedSpeed km/h",
        style: const TextStyle(fontSize: 20.0),
      ),
    );
  }

  Widget _buildDistanceToNextStep() {
    return _container(
      Text(
        _distanceToNextStep,
        style: const TextStyle(fontSize: 20.0),
      ),
    );
  }

  Container _container(Widget widget) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(5.0),
      decoration: _boxDecoration(),
      child: widget,
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.blue.shade100.withOpacity(0.8),
      boxShadow: _boxShadow(),
      borderRadius: const BorderRadius.all(Radius.circular(6.0)),
    );
  }

  List<BoxShadow> _boxShadow() {
    return [
      BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 5,
          blurRadius: 7,
          offset: const Offset(0, 3))
    ];
  }
}

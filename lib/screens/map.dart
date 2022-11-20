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

import '../config.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Future<SharedRide?> _sharedRide = getSharedRide(actualSharedRideId!);

  late final MapService _mapService;
  late Position _currentPosition;

  static const MarkerId _currentLocationMarkerId = MarkerId("currentLocation");
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    initLocationService().then((initPosition) {
      _currentPosition = initPosition;
      _initMarkers();
      positionStream().listen((streamPosition) {
        _currentPosition = streamPosition;
        _updateMarker(_currentLocationMarkerId, _currentPosition);
      });
    });
  }

  void _initMarkers() {
    iconToBitmapDescriptor(Icons.my_location).then((icon) {
      setState(() {
        _markers.add(Marker(
            markerId: _currentLocationMarkerId,
            position: _positionToLatLng(_currentPosition),
            icon: icon));
      });
    });
  }

  void _updateMarker(MarkerId id, Position position) {
    final marker = _markers.firstWhere((m) => m.markerId == id);
    setState(() {
      _markers.remove(marker);
      _markers.add(Marker(
          markerId: id,
          position: _positionToLatLng(position),
          icon: marker.icon));
    });
  }

  LatLng _positionToLatLng(Position position) =>
      LatLng(position.latitude, position.longitude);

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
                  exitSharedRide().then((value) => Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(
                          builder: (context) => const SharedRideScreen())));
                  break;
                case 1:
                  logout().then((value) => Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(
                          builder: (context) => const LoginFormScreen())));
                  break;
              }
            }),
          ],
        ),
        body: FutureBuilder<SharedRide?>(
            future: _sharedRide,
            builder:
                (BuildContext context, AsyncSnapshot<SharedRide?> snapshot) {
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
            }));
  }

  Widget _buildMap(SharedRide sharedRide) {
    final startLocation = geoCoordToLatLng(
        sharedRide.direction.routes!.first.legs!.first.startLocation!);
    final initialCameraPosition = CameraPosition(
      target: startLocation,
      zoom: 10,
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
        }, //TODO clients stomp
      ),
      Align(alignment: Alignment.topCenter, child: _buildSteps(sharedRide))
    ]);
  }

  Widget _buildSteps(SharedRide sharedRide) {
    final leg = sharedRide.direction.routes?.first.legs?.first;
    return Container(
      height: 40,
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(5.0),
      decoration: _stepsDecoration(),
      child: Text(
        overflow: TextOverflow.ellipsis,
        "${leg?.startAddress?.split(',')[0]} > ${leg?.endAddress?.split(',')[0]}",
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

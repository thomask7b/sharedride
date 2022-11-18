import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sharedride/models/sharedride.dart';
import 'package:sharedride/screens/login.dart';
import 'package:sharedride/screens/sharedride.dart';
import 'package:sharedride/services/auth_service.dart';
import 'package:sharedride/services/sharedride_service.dart';

import '../config.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Future<SharedRide?> _sharedRide = getSharedRide(actualSharedRideId!);
  final Completer<GoogleMapController> _mapController = Completer();

  final PolylinePoints _polylineUtils = PolylinePoints();

  @override
  void initState() {
    super.initState();
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
    final bounds = sharedRide.direction.routes!.first.bounds!;
    final startLocation =
        sharedRide.direction.routes!.first.legs!.first.startLocation!;
    final initialCameraPosition = CameraPosition(
      target: _geoCoordToLatLng(startLocation),
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
              polylineId: const PolylineId("route"),
              points: _decodePolylines(sharedRide))
        },
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
          // _fitMapOnBounds(controller);
        }, //TODO recupérer location + clients stomp
      ),
      Align(alignment: Alignment.topCenter, child: _buildSteps(sharedRide))
    ]);
  }

  //TODO geo_service
  List<LatLng> _decodePolylines(SharedRide sharedRide) {
    return sharedRide.direction.routes!.first.legs!.first.steps!
        .expand((step) => _polylineUtils
            .decodePolyline(step.polyline!.points!)
            .map((ptLatLng) => LatLng(ptLatLng.latitude, ptLatLng.longitude)))
        .toList();
  }

  LatLng _centerOfGeoCoordBounds(GeoCoordBounds bounds) {
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }

  LatLng _geoCoordToLatLng(GeoCoord geoCoord) {
    return LatLng(geoCoord.latitude, geoCoord.longitude);
  }

  void _fitMapOnBounds(GoogleMapController controller, GeoCoordBounds bounds) {
    final LatLngBounds latLngBounds = LatLngBounds(
        southwest:
            LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
        northeast:
            LatLng(bounds.northeast.longitude, bounds.northeast.latitude));
    controller.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 50));
    //BUG https://github.com/flutter/flutter/issues/109115
  }

  Widget _buildSteps(SharedRide sharedRide) {
    final leg = sharedRide.direction.routes?.first.legs?.first;
    return Container(
      height: 40,
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(5.0),
      decoration: _stepsDecoration(),
      child: Text(
        "${leg?.startAddress} > ${leg?.endAddress}",
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

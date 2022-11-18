import 'dart:async';

import 'package:flutter/material.dart';
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
              List<Widget> children;
              if (snapshot.hasData) {
                return const Text("Construction");
              } else if (snapshot.hasError) {
                children = <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Error: ${snapshot.error}'),
                  ),
                ];
              } else {
                children = const <Widget>[
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(), //TODO centrer
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Chargement du shared ride...'),
                  ),
                ];
              }
              return Column(children: children);
            }));
  }
}

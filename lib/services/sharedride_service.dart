import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:objectid/objectid.dart';
import 'package:sharedride/config.dart';
import 'package:sharedride/services/auth_service.dart';
import 'package:sharedride/services/db_service.dart';

import '../models/sharedride.dart';

ObjectId? _actualSharedRideId;

ObjectId? get actualSharedRideId => _actualSharedRideId;

Future<bool> hasSharedRide() async {
  if (_actualSharedRideId != null) {
    return true;
  } else {
    _actualSharedRideId = await fetchSharedRideId();
    return _actualSharedRideId != null;
  }
}

Future<bool> createSharedRide(List<String> steps) async {
  final response = await http.post(
    Uri.parse('$hostUrl/sharedride/create'),
    headers: <String, String>{'Cookie': sessionId!}..addAll(defaultHeaders),
    body: jsonEncode(steps),
  );
  if (kDebugMode) {
    print("Requête de création du shared ride envoyée.");
  }
  if (response.statusCode == 201) {
    _actualSharedRideId = ObjectId.fromHexString(
        response.headers["location"]!.replaceFirst("/sharedride/", ""));
    if (kDebugMode) {
      print(
          "Création du shared ride réussie. Son ID est : $actualSharedRideId");
    }
    saveSharedRideId(_actualSharedRideId!);
    return true;
  }
  _actualSharedRideId = null;
  return false;
}

Future<SharedRide?> getSharedRide(ObjectId sharedRideId) async {
  final response = await http.get(
      Uri.parse('$hostUrl/sharedride/$sharedRideId'),
      headers: <String, String>{
        'Cookie': sessionId!,
        'Content-Type': 'application/json; charset=UTF-8',
      });
  if (kDebugMode) {
    print("Requête de récupération du shared ride envoyée.");
  }
  if (response.statusCode == 200) {
    _actualSharedRideId = sharedRideId;
    if (kDebugMode) {
      print("Réception du shared ride.");
    }
    saveSharedRideId(_actualSharedRideId!);
    return SharedRide.fromJson(actualSharedRideId!, jsonDecode(response.body));
  }
  deleteSharedRideId();
  _actualSharedRideId = null;
  return null;
}

Future<void> exitSharedRide() async {
  //TODO appeler route /sharedride/exit
  _actualSharedRideId = null;
  await deleteSharedRideId();
}

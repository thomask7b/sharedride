import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:objectid/objectid.dart';
import 'package:sharedride/config.dart';
import 'package:sharedride/services/auth_service.dart';

import '../models/sharedride.dart';

ObjectId? actualSharedRideId;

Future<bool> createSharedRide(List<String> steps) async {
  final response = await http.post(
    Uri.parse('$hostUrl/sharedride/create'),
    headers: <String, String>{
      'Cookie': sessionId!,
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(steps),
  );
  if (kDebugMode) {
    print("Requête de création du shared ride envoyée.");
  }
  if (response.statusCode == 201) {
    actualSharedRideId = ObjectId.fromHexString(
        response.headers["location"]!.replaceFirst("/sharedride/", ""));
    if (kDebugMode) {
      print(
          "Création du shared ride réussie. Son ID est : $actualSharedRideId");
    }
    return true;
  }
  actualSharedRideId = null;
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
    actualSharedRideId = sharedRideId;
    if (kDebugMode) {
      print("Réception du shared ride.");
    }
    return SharedRide.fromJson(actualSharedRideId!, jsonDecode(response.body));
  }
  actualSharedRideId = null;
  return null;
}

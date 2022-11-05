import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sharedride/config.dart';
import 'package:sharedride/models/user.dart';

String? sessionId;
User? authenticatedUser;

Future<bool> authenticate(User user) async {
  final response = await http.post(
    Uri.parse('$hostUrl/auth'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, String>{'name': user.name, 'password': user.password}),
  );
  if (kDebugMode) {
    print("Requête d'authentification envoyée.");
  }
  if (response.statusCode == 200) {
    sessionId = response.headers['set-cookie'];
    if (kDebugMode) {
      print("Authentification réussie.");
    }
    authenticatedUser = user;
    return true;
  }
  sessionId = null;
  authenticatedUser = null;
  return false;
}

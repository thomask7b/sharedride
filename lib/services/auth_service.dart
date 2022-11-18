import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sharedride/config.dart';
import 'package:sharedride/models/user.dart';

import 'db_service.dart';

String? _sessionId;
User? _authenticatedUser;

String? get sessionId => _sessionId;

User? get authenticatedUser => _authenticatedUser;

Future<bool> authenticateSavedUser() async {
  _authenticatedUser ??= await fetchUser();
  if (authenticatedUser != null) {
    return await authenticate(authenticatedUser!);
  }
  return false;
}

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
    _sessionId = response.headers['set-cookie'];
    if (kDebugMode) {
      print("Authentification réussie.");
    }
    _authenticatedUser = user;
    saveUser(_authenticatedUser!);
    return true;
  }
  deleteUser();
  _sessionId = null;
  _authenticatedUser = null;
  return false;
}

Future<void> logout() async {
  _sessionId = null;
  _authenticatedUser = null;
  await deleteUser();
}

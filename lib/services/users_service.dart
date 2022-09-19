import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sharedride/config.dart';
import 'package:sharedride/models/user.dart';

Future<bool> authenticate(User user) async {
  final response = await http.post(
    Uri.parse(hostUrl + '/auth'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, String>{'name': user.name, 'password': user.password}),
  );
  print("Requête d'authentification envoyée.");
  return response.statusCode == 200;
}

Future<bool> createAccount(User user) async {
  final response = await http.post(
    Uri.parse(hostUrl + '/users/create'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, String>{'name': user.name, 'password': user.password}),
  );
  print("Requête de création de compte envoyée.");
  return response.statusCode == 201;
}

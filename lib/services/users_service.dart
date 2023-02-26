import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sharedride/config.dart';
import 'package:sharedride/models/user.dart';

Future<bool> createAccount(User user) async {
  final response = await http.post(
    Uri.parse('$hostUrl/users/create'),
    headers: defaultHeaders,
    body: jsonEncode(
        <String, String>{'name': user.name, 'password': user.password}),
  );
  if (kDebugMode) {
    print("Requête de création de compte envoyée.");
  }
  return response.statusCode == 201;
}

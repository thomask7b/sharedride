import 'dart:convert';

import 'package:sharedride/config.dart';
import 'package:sharedride/models/location.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';

import 'auth_service.dart';

late StompClient _receiveClient;

void startReceiveClient(Function(MapEntry<String, Location>) subscriber) {
  _receiveClient = StompClient(
      config: StompConfig(
    url: '${hostUrl.replaceFirst("http", "ws")}/sharedride-ws-endpoint',
    webSocketConnectHeaders: {
      'Cookie': sessionId!,
    },
    onConnect: (frame) {
      _receiveClient.subscribe(
        destination: '/user/sharedride-ws/locations',
        callback: (frame) {
          final message = jsonDecode(frame.body!);
          final username = message['username'] as String;
          final location = Location.fromMap(message['location']);
          subscriber(MapEntry(username, location));
        },
      );
    },
  ));
  _receiveClient.activate();
}

void stopReceiveClient() {
  _receiveClient.deactivate();
}

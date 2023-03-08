import 'dart:convert';

import 'package:sharedride/config.dart';
import 'package:sharedride/models/location.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';

import 'auth_service.dart';

final String _websocketEndpoint =
    '${hostUrl.replaceFirst("http", "ws")}/sharedride-ws-endpoint';
final Map<String, String> _websocketConnectHeaders = {
  'Cookie': sessionId!,
};

StompClient? _receiveClient;
StompClient? _emitClient;

void startReceiveClient(Function(MapEntry<String, Location>) subscriber) {
  _receiveClient = StompClient(
      config: StompConfig(
    url: _websocketEndpoint,
    webSocketConnectHeaders: _websocketConnectHeaders,
    onConnect: (frame) {
      _receiveClient?.subscribe(
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
  _receiveClient?.activate();
}

void startEmitClient() {
  _emitClient = StompClient(
      config: StompConfig(
    url: _websocketEndpoint,
    webSocketConnectHeaders: _websocketConnectHeaders,
  ));
  _emitClient?.activate();
}

void sendStompLocation(String sharedRideId, Location location) {
  _emitClient?.send(
      destination: '/app/location',
      body: jsonEncode(<String, dynamic>{
        'sharedRideId': sharedRideId,
        'username': authenticatedUser!.name,
        'location': location
      }));
}

void stopReceiveClient() {
  _receiveClient?.deactivate();
}

void stopEmitClient() {
  _emitClient?.deactivate();
}

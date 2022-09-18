import 'package:flutter/material.dart';

import 'screens/login.dart';

void main() => runApp(const SharedRideApp());

class SharedRideApp extends StatelessWidget {
  const SharedRideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Shared Ride';

    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: const LoginFormScreen(),
      ),
    );
  }
}



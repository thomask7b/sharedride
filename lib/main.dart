import 'package:flutter/material.dart';
import 'package:sharedride/config.dart';

import 'screens/login.dart';

void main() => runApp(const SharedRideApp());

class SharedRideApp extends StatelessWidget {
  const SharedRideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: appName, home: LoginFormScreen());
  }
}

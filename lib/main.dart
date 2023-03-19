import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sharedride/config.dart';
import 'package:sharedride/services/db_service.dart';

import 'screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDb();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const SharedRideApp());
  });
}

class SharedRideApp extends StatelessWidget {
  const SharedRideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: appName, home: LoginFormScreen());
  }
}

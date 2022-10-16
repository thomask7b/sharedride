import 'package:flutter/material.dart';
import 'package:sharedride/models/user.dart';

import '../config.dart';

class SharedRideScreen extends StatefulWidget {
  final User user;

  const SharedRideScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: Center(
        child: Text(
          'Bienvenu ${widget.user.name}',
          style: const TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}

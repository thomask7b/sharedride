import 'package:flutter/material.dart';

abstract class ProgressibleState<T extends StatefulWidget> extends State<T> {
  bool _isLoading = true;

  @protected
  bool get isLoading => _isLoading;

  void showProgress() {
    setState(() {
      _isLoading = true;
    });
  }

  void hideProgress() {
    setState(() {
      _isLoading = false;
    });
  }
}

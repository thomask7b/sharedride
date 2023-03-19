import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({super.key, required this.onTap, required this.text});

  final Function() onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ));
  }
}

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final String text;
  final Color color;


  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.color,
    });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: EdgeInsets.all(20),
        margin: EdgeInsetsDirectional.symmetric(horizontal: 25),
        child: Center(
          child: Text(text),
        ),
      ),
    );
  }
}
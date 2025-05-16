import 'package:flutter/material.dart';

final String baseUrl = "https://192.168.137.1:7109/api";

void showSafeSnackBar(BuildContext context, String message, Color color) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 8),
    ),
  );
}

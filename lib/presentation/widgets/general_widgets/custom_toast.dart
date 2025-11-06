import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastType { success, info, error }

class ToastHelper {
  static void showSuccess(String message) {
    CustomToast.show(message: message, type: ToastType.success);
  }

  static void showInfo(String message) {
    CustomToast.show(message: message, type: ToastType.info);
  }

  static void showError(String message) {
    CustomToast.show(message: message, type: ToastType.error);
  }
}

class CustomToast {
  static void show({
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;

    // Set the appropriate color based on toast type
    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green;
        break;
      case ToastType.info:
        backgroundColor = Colors.blue;
        break;
      case ToastType.error:
        backgroundColor = Colors.red;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
      timeInSecForIosWeb: duration.inSeconds,
    );
  }
}
import 'package:flutter/material.dart';

class MoodColorUtil {
  static List<Color> getMoodColor(String emoji) {
    switch (emoji) {
      case '😊':
        return [
          Colors.green.shade100,
          Colors.green.shade200,
          Colors.green.shade400,
        ];
      case '😆':
        return [
          Colors.teal.shade100,
          Colors.teal.shade200,
          Colors.teal.shade400,
        ];
      case '😘':
        return [
          Colors.pink.shade100,
          Colors.pink.shade200,
          Colors.pink.shade400,
        ];
      case '😌':
        return [
          Colors.lightBlue.shade100,
          Colors.lightBlue.shade200,
          Colors.lightBlue.shade400,
        ];
      case '🤔':
        return [
          Colors.purple.shade100,
          Colors.purple.shade200,
          Colors.purple.shade400,
        ];
      case '😕':
        return [
          Colors.cyanAccent.shade100,
          Colors.cyanAccent.shade200,
          Colors.cyanAccent.shade400,
        ];
      case '☹️':
        return [
          Colors.brown.shade100,
          Colors.brown.shade200,
          Colors.brown.shade400,
        ];
      case '😭':
        return [
          Colors.blue.shade100,
          Colors.blue.shade200,
          Colors.blue.shade400,
        ];
      case '🥺':
        return [
          Colors.deepPurple.shade100,
          Colors.deepPurple.shade200,
          Colors.deepPurple.shade400,
        ];
      case '😡':
        return [Colors.red.shade100, Colors.red.shade200, Colors.red.shade400];
      case '🤢':
        return [
          Colors.lightGreen.shade100,
          Colors.lightGreen.shade200,
          Colors.lightGreen.shade400,
        ];
      case '😴':
        return [
          Colors.indigo.shade100,
          Colors.indigo.shade200,
          Colors.indigo.shade400,
        ];
      default:
        return [
          Colors.grey.shade100,
          Colors.grey.shade200,
          Colors.grey.shade400,
        ];
    }
  }
}

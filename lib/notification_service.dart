import 'package:flutter/material.dart';

class NotificationService {
  // Global messenger key to show SnackBars anywhere in the app
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Show a simple in-app notification
  /// [title] - notification title
  /// [body] - notification message
  static void show(String title, String body) {
    final snackBar = SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(body),
        ],
      ),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    messengerKey.currentState?.showSnackBar(snackBar);
  }
}

import 'package:flutter/material.dart';

class NotificationService {
  // Global messenger key to show SnackBars anywhere in the app
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Show a simple in-app notification
  /// [title] - notification title
  /// [body] - notification message
  static void show(String title, String body) {
    final context = messengerKey.currentContext;
    if (context == null) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    
    final snackBar = SnackBar(
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth - 32, // Account for margins
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: isSmallScreen ? 2 : 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 12,
      ),
    );

    messengerKey.currentState?.showSnackBar(snackBar);
  }
}

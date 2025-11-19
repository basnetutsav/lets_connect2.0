import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/login_page.dart';
import 'pages/top_bar.dart';
import 'pages/job_search.dart';
import 'pages/inbox_chat.dart';

// ⭐ ADD THIS IMPORT FOR NOTIFICATIONS
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // Initialize Firebase
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    const Color seedColor = Color(0xFF6C88BF);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Lets Connect',
<<<<<<< HEAD

      // ⭐ REQUIRED FOR IN-APP NOTIFICATIONS
      scaffoldMessengerKey: NotificationService.messengerKey,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // ✅ First screen after login
      home: LoginPage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
=======
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: seedColor),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: seedColor),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
        '/top_bar': (context) => TopBar(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
        '/job_search': (context) => const JobSearch(),
        '/chat': (context) => const InboxPage(),
      },
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)
    );
  }
}

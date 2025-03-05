import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GroceryGuru',
      themeMode: Platform.isAndroid ? ThemeMode.dark : ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.grey[800],
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6D6B5F), // Muted beige from your logo
          secondary: Color(0xFF8B8878), // Light greyish-beige
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        scaffoldBackgroundColor: const Color.fromARGB(255, 50, 50, 50),
        cardColor: Colors.grey[850],
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB4AF91), // Lighter beige for contrast
          secondary: Color(0xFFA6A08C), // Softer beige-grey
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

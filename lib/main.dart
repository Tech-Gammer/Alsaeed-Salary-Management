import 'package:flutter/material.dart';

import 'Authentication/LoginPage.dart';
import 'Authentication/RegisterPage.dart';
import 'dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Salary Management",
      theme: ThemeData(primarySwatch: Colors.blue),
      // home: const RegisterPage(),
      initialRoute: '/home',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(), // <-- add your home screen here
      },
    );
  }
}

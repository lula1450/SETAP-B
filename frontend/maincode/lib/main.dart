import 'package:flutter/material.dart';
import 'package:maincode/login_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petsync',
      theme: ThemeData(
        // Seed color based on your ARGB Top Color
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 139, 174, 174)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

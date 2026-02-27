import 'package:flutter/material.dart';
import 'dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petsync',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color.fromRGBO(76, 40, 139, 1)),
      ),
      debugShowCheckedModeBanner: false,
      home: const DashboardPage(),
    );
  }
}



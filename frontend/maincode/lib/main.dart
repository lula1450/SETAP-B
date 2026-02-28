import 'package:flutter/material.dart';
import 'dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petsync',
      theme: ThemeData(
        // Seed color based on your ARGB Top Color
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 139, 174, 174)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const DashboardPage(),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 0b220b1d6c1abc911f2f07b2e069f7d6ecc81175

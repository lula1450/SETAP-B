import 'package:flutter/material.dart';

void main() => runApp(const PetCareApp());

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('Pet Care App')),
      ),
    );
  }
}
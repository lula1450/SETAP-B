import 'package:flutter/material.dart';

class FeedingSchedulePage extends StatelessWidget {
  const FeedingSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding Schedule'),
      ),
      body: const Center(
        child: Text('This is the Feeding Schedule page.'),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class PetInfoPage extends StatelessWidget {
  const PetInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Information'),
      ),
      body: const Center(
        child: Text('Display pet information here'),
      ),
    );
  }
}

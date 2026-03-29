import 'package:flutter/material.dart';

class VetContactsPage extends StatelessWidget {
  const VetContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Contacts'),
      ),
      body: const Center(
        child: Text('This is the Vet Contact page.'),
      ),
    );
  }
}
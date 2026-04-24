import 'package:flutter/material.dart';
import 'package:maincode/widgets/app_drawer.dart';

class VetContactsPage extends StatelessWidget {
  const VetContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Vet Contacts'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text('This is the Vet Contact page.'),
      ),
    );
  }
}
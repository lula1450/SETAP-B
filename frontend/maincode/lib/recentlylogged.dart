import 'package:flutter/material.dart';

class RecentlyLoggedDataPage extends StatelessWidget {
  const RecentlyLoggedDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Logged Data'),
      ),
      body: const Center(
        child: Text('Display recently logged data here'),
      ),
    );
  }
}

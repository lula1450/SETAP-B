import 'package:flutter/material.dart';

class GenerateReport extends StatelessWidget {
  const GenerateReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
      ),
      body: const Center(
        child: Text('Generate report'),
      ),
    );
  }
}
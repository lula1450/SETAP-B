import 'package:flutter/material.dart';

class FeedingSchedulePage extends StatelessWidget {
  const FeedingSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feeding Schedule')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Today\'s Feeding Schedule',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeedingCard('Morning', '8:00 AM', 'Dry Food'),
          _buildFeedingCard('Afternoon', '12:00 PM', 'Wet Food'),
          _buildFeedingCard('Evening', '6:00 PM', 'Dry Food'),
        ],
      ),
    );
  }

  Widget _buildFeedingCard(String timeOfDay, String time, String food) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(Icons.restaurant_menu, color: Colors.green[700]),
        title: Text('$timeOfDay - $time'),
        subtitle: Text('Food Type: $food'),
      ),
    );
  }
}

// ─── Entry point ────────────────────────────────────────────────────────────
void main() => runApp(const PetCareApp());

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const FeedingSchedulePage(),
    );
  }
}

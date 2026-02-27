import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F4), // Mint green from design
      appBar: AppBar(
        title: const Text('Pet Name'), // Updated to match your pet name
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Prevents bottom overflow
        child: Column(
          children: [
            // 1. Calendar Placeholder
            Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text("Calendar Widget Area")),
            ),

            // 2. Middle Action Row with "Log daily metrics"
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton("Log daily\nmetrics"),
                  _actionButton("Recently\nlogged data"),
                  _actionButton("Find out\nmore about pet"),
                  const Column(
                    children: [
                      Icon(Icons.sentiment_very_dissatisfied, size: 40, color: Colors.orange),
                      Text("Current mood", style: TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Bottom Grid Buttons
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              padding: const EdgeInsets.all(16),
              children: [
                _gridButton("Generate\nreport"),
                _gridButton("Health\nrecords"),
                _gridButton("Feeding\nschedule"),
                _gridButton("Change\nPet"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // HELPER FUNCTIONS

  Widget _actionButton(String text) {
    return Container(
      width: 75,
      height: 75,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _gridButton(String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: Text(
          label, 
          textAlign: TextAlign.center, 
          style: const TextStyle(fontSize: 9)
        ),
      ),
    );
  }
}
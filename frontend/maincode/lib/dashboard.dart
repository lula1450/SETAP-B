import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F4), 
      appBar: AppBar(
        title: const Text('Pet Name'), 
        centerTitle: true,
      ),
      body: SingleChildScrollView( 
        child: Column(
          children: [
            
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
    return InkWell(
      onTap: () {
        // Functionality to be added later
      },
      child: Container(
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
      ),
    );
  }

  Widget _gridButton(String label) {
    return InkWell(
      onTap: () {
        // Functionality to be added later
      },
      child: Container(
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
      ),
    );
  }
}
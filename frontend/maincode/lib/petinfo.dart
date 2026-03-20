import 'package:flutter/material.dart';

class PetInfoPage extends StatelessWidget {
  const PetInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        elevation: 0, // Removes the shadow to blend with the gradient
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pet Information',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // THE OMBRE GRADIENT
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 139, 174, 174), // Top Color (Matches AppBar)
              Color.fromARGB(255, 178, 211, 194), // Middle Transition
              Color.fromARGB(255, 224, 247, 244), // Bottom Color
            ],
          ),
        ),
        child: const SingleChildScrollView(
          child: Column(
            children: [
              // Add your Pet Profile widgets here!
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  } // Fixed: Changed comma to brace
}
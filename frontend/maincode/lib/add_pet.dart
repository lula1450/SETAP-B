import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/pet_service.dart'; // Ensure this exists

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  int _selectedSpeciesId = 1; // Default to Dog

  // This list should match your SpeciesType Enum in Python
  final List<Map<String, dynamic>> _species = [
    {'id': 1, 'name': 'Dog'},
    {'id': 2, 'name': 'Cat'},
    {'id': 3, 'name': 'Rabbit'},
    {'id': 4, 'name': 'Hamster'},
    {'id': 5, 'name': 'Bird'},
    {'id': 6, 'name': 'Snake'},
  ];

  void _savePet() async {
    final success = await PetService().createPet(
      _nameController.text,
      _selectedSpeciesId,
      _cityController.text,
    );

    if (success && mounted) {
      Navigator.pop(context); // Return to Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Your Pet")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Pet Name")),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _selectedSpeciesId,
              items: _species.map((s) => DropdownMenuItem<int>(
                value: s['id'], child: Text(s['name']))).toList(),
              onChanged: (val) => setState(() => _selectedSpeciesId = val!),
              decoration: const InputDecoration(labelText: "Species"),
            ),
            TextField(controller: _cityController, decoration: const InputDecoration(labelText: "City")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _savePet, child: const Text("Complete Registration")),
          ],
        ),
      ),
    );
  }
}
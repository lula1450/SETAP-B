import 'package:flutter/material.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:maincode/screens/dashboard.dart'; // Ensure this path matches your project structure

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final PetService _petService = PetService();
  
  int _selectedSpeciesId = 1; // Default to Dog - Labrador
  bool _isLoading = false;

  // Exact matches for the 12 species/breeds in your database
  final List<Map<String, dynamic>> _speciesOptions = [
    {'id': 1, 'name': 'Dog - Labrador'},
    {'id': 2, 'name': 'Dog - Golden Retriever'},
    {'id': 3, 'name': 'Cat - Maine Coon'},
    {'id': 4, 'name': 'Cat - Siamese'},
    {'id': 5, 'name': 'Rabbit - Holland Lop'},
    {'id': 6, 'name': 'Rabbit - Rex'},
    {'id': 7, 'name': 'Hamster - Syrian'},
    {'id': 8, 'name': 'Hamster - Roborovski'},
    {'id': 9, 'name': 'Bird - African Grey'},
    {'id': 10, 'name': 'Bird - Cockatiel'},
    {'id': 11, 'name': 'Snake - Corn Snake'},
    {'id': 12, 'name': 'Snake - Ball Python'},
  ];

  void _handleSave() async {
    // 1. Validation: Don't allow empty names
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name for your pet!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Call the service to save to FastAPI
    final newPetId = await _petService.createPet(
      petFirstName: _firstNameController.text.trim(),
      petLastName: _lastNameController.text.trim(),
      speciesId: _selectedSpeciesId,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (newPetId != -1) {
        // 3. SUCCESS: Clear the navigation stack and go to Dashboard, selecting the new pet
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage(initialPetId: newPetId)),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to register pet. Please check your connection.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register New Pet"),
        backgroundColor: const Color(0xFF8BAEAE),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8BAEAE), Color(0xFFE0F7F4)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets, size: 50, color: Color(0xFF8BAEAE)),
                    const SizedBox(height: 10),
                    const Text(
                      "Pet Registration",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    
                    // First Name Field
                    TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: "Pet First Name",
                        hintText: "e.g. Teddy",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Last Name Field
                    TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: "Pet Last Name (Optional)",
                        hintText: "e.g. Bear",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Breed Selection
                    DropdownButtonFormField<int>(
                      initialValue: _selectedSpeciesId,
                      decoration: InputDecoration(
                        labelText: "Select Breed",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.list),
                      ),
                      items: _speciesOptions.map((s) => DropdownMenuItem<int>(
                        value: s['id'], 
                        child: Text(s['name']),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedSpeciesId = val!),
                    ),
                    const SizedBox(height: 35),
                    
                    // Submit Button
                    _isLoading 
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8BAEAE),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            onPressed: _handleSave,
                            child: const Text(
                              "Complete Registration", 
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
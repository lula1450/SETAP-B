import 'package:flutter/material.dart';
import 'package:maincode/add_pet.dart';
import 'package:maincode/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers for all required backend fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _cityController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleRegister() async {
    // 1. Basic Validation
    if (_firstNameController.text.isEmpty || _emailController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in required fields (Name, Email, Address)")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Call the updated AuthService
    final success = await _authService.signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty ? "User" : _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? "0000000000" : _phoneController.text.trim(),
      address: _addressController.text.trim(),
      postcode: _postcodeController.text.trim(),
      city: _cityController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // 3. SUCCESS: Go straight to Add Pet Page and clear history
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AddPetPage()),
          (route) => false, // Prevents going back to registration
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed. Please check your details.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: const Color(0xFF8BAEAE),
      ),
      body: SingleChildScrollView( // Added scroll so keyboard doesn't block fields
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: "First Name")),
            TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: "Last Name")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
            const Divider(height: 40),
            const Text("Home Address", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Address Line 1")),
            TextField(controller: _postcodeController, decoration: const InputDecoration(labelText: "Postcode")),
            TextField(controller: _cityController, decoration: const InputDecoration(labelText: "City")),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BAEAE),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _handleRegister, 
                  child: const Text("Complete Sign Up", style: TextStyle(color: Colors.white)),
                ),
          ],
        ),
      ),
    );
  }
}
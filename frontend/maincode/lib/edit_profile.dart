import 'package:flutter/material.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final PetService _service = PetService();

  bool _isEditing = false; // Controls whether fields are editable

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('owner_email') ?? "";
      _passwordController.text = "********"; // placeholder for now
      _firstNameController.text = prefs.getString('owner_first_name') ?? "";
      _lastNameController.text = prefs.getString('owner_last_name') ?? "";
      _phoneController.text = prefs.getString('owner_phone_number') ?? "";
      _addressController.text = prefs.getString('owner_address1') ?? "";
    });
  }

Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;

  final prefs = await SharedPreferences.getInstance();
  final ownerId = prefs.getInt('owner_id') ?? 0;

  final data = {
    "owner_email": _emailController.text.trim(),
    "owner_first_name": _firstNameController.text.trim(),
    "owner_last_name": _lastNameController.text.trim(),
    "owner_phone_number": _phoneController.text.trim(),
    "owner_address1": _addressController.text.trim(),
  };

  final password = _passwordController.text.trim();
  if (password.isNotEmpty && password != "********") {
    data["owner_password"] = password;
  }

  final success = await _service.updateOwnerProfile(ownerId, data);

  if (success && mounted) {

    await prefs.setString('owner_email', data["owner_email"]!);
    await prefs.setString('owner_first_name', data["owner_first_name"]!);
    await prefs.setString('owner_last_name', data["owner_last_name"]!);
    await prefs.setString('owner_phone_number', data["owner_phone_number"]!);
    await prefs.setString('owner_address1', data["owner_address1"]!);

    showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Success"),
        content: const Text("Your profile has been updated."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();       
          },
          child: const Text("Back to Dashboard"),
        ),
      ],
    );
  },
);

    setState(() {
      _isEditing = false;
      if (data.containsKey("owner_password")) {
        _passwordController.text = "********";
      }
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF8BAEAE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_emailController, "Email", isEmail: true),
              _buildTextField(_passwordController, "Password", isPassword: true),
              _buildTextField(_firstNameController, "First Name"),
              _buildTextField(_lastNameController, "Last Name"),
              _buildTextField(_phoneController, "Phone Number", isPhone: true),
              _buildTextField(_addressController, "Address"),
              const SizedBox(height: 30),
              _isEditing
                  ? ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BAEAE),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          _passwordController.text = ""; // allow password update
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BAEAE),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Change Account Info", style: TextStyle(color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPhone = false, bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: isPhone
            ? TextInputType.phone
            : isEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (!_isEditing) return null;
          if (value == null || value.isEmpty) return "Cannot be empty";
          return null;
        },
      ),
    );
  }
}
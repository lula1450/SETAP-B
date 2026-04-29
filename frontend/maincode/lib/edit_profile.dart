import 'package:flutter/material.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/widgets/app_drawer.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final PetService _service = PetService();

  bool _isEditing = false; // Controls whether fields are editable
  bool _showPassword = false; // Controls password visibility

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
        
    setState(() {
      _emailController.text = prefs.getString('owner_email') ?? "";
      _passwordController.text = "••••••••"; // Show dots if password is set
      _firstNameController.text = prefs.getString('owner_first_name') ?? "";
      _lastNameController.text = prefs.getString('owner_last_name') ?? "";
      _phoneController.text = prefs.getString('owner_phone_number') ?? "";
      _addressController.text = prefs.getString('owner_address1') ?? "";
      _postcodeController.text = prefs.getString('owner_postcode') ?? "";
      _cityController.text = prefs.getString('owner_city') ?? "";
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
    "owner_postcode": _postcodeController.text.trim(),
    "owner_city": _cityController.text.trim(),
  };

  final password = _passwordController.text.trim();
  if (password.isNotEmpty && password != "••••••••" && password != "********") {
    data["password"] = password;
  }

  debugPrint("DEBUG: Saving profile with data: $data");
  debugPrint("DEBUG: Owner ID: $ownerId");
  
  final success = await _service.updateOwnerProfile(ownerId, data);

  debugPrint("DEBUG: Update success: $success");

  if (success && mounted) {

    // Update SharedPreferences with new values
    await prefs.setString('owner_email', data["owner_email"]!);
    await prefs.setString('owner_first_name', data["owner_first_name"]!);
    await prefs.setString('owner_last_name', data["owner_last_name"]!);
    await prefs.setString('owner_phone_number', data["owner_phone_number"]!);
    await prefs.setString('owner_address1', data["owner_address1"]!);
    await prefs.setString('owner_postcode', data["owner_postcode"]!);
    await prefs.setString('owner_city', data["owner_city"]!);
    
    // Update password if it was changed
    if (data.containsKey("password")) {
      await prefs.setString('owner_password', data["password"]!);
    }
    
    debugPrint("DEBUG: SharedPreferences updated successfully");

    // Update UI with saved values and exit edit mode
    setState(() {
      _isEditing = false;
      _showPassword = false; // Reset password visibility
      // Show dots for password in view mode
      _passwordController.text = "••••••••";
    });

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
  } else {
    debugPrint("DEBUG: Update failed or widget not mounted");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile. Please try again.")),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF8BAEAE),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_emailController, "Email", isEmail: true),
              _buildPasswordField(),
              _buildTextField(_firstNameController, "First Name"),
              _buildTextField(_lastNameController, "Last Name"),
              _buildTextField(_phoneController, "Phone Number", isPhone: true),
              _buildTextField(_addressController, "Address"),
              _buildTextField(_postcodeController, "Postcode"),
              _buildTextField(_cityController, "City"),
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
                      onPressed: () async {
                        // Load the current password from SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        final currentPassword = prefs.getString('owner_password') ?? "";
                        
                        debugPrint("DEBUG: Fetching current password");
                        debugPrint("DEBUG: Current password loaded: $currentPassword");
                        
                        setState(() {
                          _isEditing = true;
                          _showPassword = false; // Reset visibility when entering edit mode
                          // Load the actual password from SharedPreferences
                          _passwordController.text = currentPassword;
                          debugPrint("DEBUG: Password set in controller: ${_passwordController.text}");
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
    // Don't obscure text if we're showing the password placeholder and not editing
    bool shouldObscure = isPassword && _isEditing;
    
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
        obscureText: shouldObscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[200],
        ),
        style: TextStyle(
          color: _isEditing ? Colors.black : Colors.grey[700],
        ),
        validator: (value) {
          if (!_isEditing) return null;
          if (value == null || value.isEmpty) return "Cannot be empty";
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: _passwordController,
        enabled: _isEditing,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          labelText: "Password",
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[200],
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF8BAEAE),
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
        ),
        style: TextStyle(
          color: _isEditing ? Colors.black : Colors.grey[700],
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
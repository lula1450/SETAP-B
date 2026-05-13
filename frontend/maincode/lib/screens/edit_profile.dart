// This page allows users to view and edit their profile information (name, email, password).
// Fields are initially read-only and enable for editing when user taps "Change Account Info" button.
// Changes are persisted to SharedPreferences and user is navigated back to dashboard on success.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:maincode/services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _showPassword = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Loads user's current profile data from SharedPreferences and populates form fields.
  /// Password field displays masked placeholder (••••••••) for security.
  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('owner_first_name') ?? '';
      _lastNameController.text = prefs.getString('owner_last_name') ?? '';
      _emailController.text = prefs.getString('owner_email') ?? '';
      // Display masked password for security (actual password change not yet implemented)
      _passwordController.text = '••••••••';
    });
  }

  /// Validates form, saves profile changes to backend and SharedPreferences, disables editing mode,
  /// displays success dialog, and navigates back to dashboard on confirmation.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('owner_id');
    if (ownerId == null) return;

    final newPassword = _passwordController.text.trim();

    final success = await AuthService().updateProfile(
      ownerId: ownerId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      newPassword: newPassword.isNotEmpty ? newPassword : null,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
      return;
    }

    await prefs.setString('owner_first_name', _firstNameController.text.trim());
    await prefs.setString('owner_last_name', _lastNameController.text.trim());
    await prefs.setString('owner_email', _emailController.text.trim());

    if (!mounted) return;

    setState(() {
      _isEditing = false;
      _showPassword = false;
      _passwordController.text = '••••••••';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
      ),
    );
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
              _buildTextField(_firstNameController, "First Name"),
              _buildTextField(_lastNameController, "Last Name"),
              _buildTextField(_emailController, "Email", isEmail: true),
              _buildPasswordField(),
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
                          _showPassword = false;
                          _passwordController.text = '';
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

  /// Builds reusable text field that toggles between read-only and editable based on _isEditing state.
  /// Shows visual feedback via background color and text color when field is disabled.
  Widget _buildTextField(TextEditingController controller, String label, {bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing, // Field is read-only unless editing mode is active
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
          disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
          filled: true,
          // Gray background when disabled, white when enabled for visual feedback
          fillColor: _isEditing ? Colors.white : Colors.grey[200],
        ),
        style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700]),
        // Only validate when in editing mode
        validator: (value) {
          if (!_isEditing) return null;
          if (value == null || value.isEmpty) return "Cannot be empty";
          return null;
        },
      ),
    );
  }

  /// Builds password field with visibility toggle button. Field is read-only unless in editing mode.
  /// Obscures text by default for security; user can toggle visibility with eye icon.
  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: _passwordController,
        enabled: _isEditing, // Field is read-only unless editing mode is active
        obscureText: !_showPassword, // Obscure by default, show when _showPassword is true
        decoration: InputDecoration(
          labelText: "Password",
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
          disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
          filled: true,
          // Gray background when disabled, white when enabled for visual feedback
          fillColor: _isEditing ? Colors.white : Colors.grey[200],
          // Visibility toggle button to show/hide password
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF8BAEAE),
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700]),
        // Only validate when in editing mode
        validator: (value) {
          if (!_isEditing) return null;
          if (value == null || value.isEmpty) return "Cannot be empty";
          return null;
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/widgets/app_drawer.dart';

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

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('owner_first_name') ?? '';
      _lastNameController.text = prefs.getString('owner_last_name') ?? '';
      _emailController.text = prefs.getString('owner_email') ?? '';
      _passwordController.text = '••••••••';
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('owner_first_name', _firstNameController.text.trim());
    await prefs.setString('owner_last_name', _lastNameController.text.trim());
    await prefs.setString('owner_email', _emailController.text.trim());

    final password = _passwordController.text.trim();
    if (password.isNotEmpty && password != '••••••••') {
      await prefs.setString('owner_password', password);
    }

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
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final currentPassword = prefs.getString('owner_password') ?? '';
                        setState(() {
                          _isEditing = true;
                          _showPassword = false;
                          _passwordController.text = currentPassword;
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

  Widget _buildTextField(TextEditingController controller, String label, {bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
          disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[200],
        ),
        style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700]),
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
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
          disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[200],
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF8BAEAE),
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700]),
        validator: (value) {
          if (!_isEditing) return null;
          if (value == null || value.isEmpty) return "Cannot be empty";
          return null;
        },
      ),
    );
  }
}
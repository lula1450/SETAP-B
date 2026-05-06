import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VetContactsPage extends StatefulWidget {
  final List<dynamic> pets;
  final int selectedPetIndex;

  const VetContactsPage({super.key, required this.pets, required this.selectedPetIndex});

  @override
  State<VetContactsPage> createState() => _VetContactsPageState();
}

class _VetContactsPageState extends State<VetContactsPage> {
  List<Map<String, dynamic>> _vetContacts = [];
  bool _isLoading = true;

  static const String _storageKey = 'vet_contacts';

  static const List<Color> _petColors = [
    Color.fromARGB(255, 146, 179, 236),
    Color.fromRGBO(212, 162, 221, 1),
    Color.fromARGB(255, 182, 139, 83),
    Color.fromRGBO(223, 128, 158, 1),
    Color.fromARGB(255, 126, 140, 224),
    Color.fromARGB(255, 255, 171, 145),
    Color.fromARGB(255, 167, 235, 244),
    Color.fromARGB(255, 219, 247, 240),
  ];

  Color _colorForPetId(int? petId) {
    if (petId == null) return const Color(0xFF8BAEAE);
    final index = widget.pets.indexWhere((p) => p['pet_id'] == petId);
    if (index < 0) return const Color(0xFF8BAEAE);
    return _petColors[index % _petColors.length];
  }

  String _nameForPetId(int? petId) {
    if (petId == null) return '';
    final pet = widget.pets.firstWhere(
      (p) => p['pet_id'] == petId,
      orElse: () => null,
    );
    return pet?['pet_first_name'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadVetContacts();
  }

  Future<void> _loadVetContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      final contacts = <Map<String, dynamic>>[];
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        for (final item in list) {
          contacts.add(Map<String, dynamic>.from(item as Map));
        }
      }
      if (mounted) {
        setState(() {
          _vetContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading vet contacts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _persistContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_vetContacts));
  }

  Future<void> _addVetContact(Map<String, dynamic> contact) async {
    setState(() {
      _vetContacts.add({
        'vet_id': DateTime.now().millisecondsSinceEpoch,
        'pet_id': contact['pet_id'],
        'name': contact['name'] ?? '',
        'phone': contact['phone'] ?? '',
        'email': contact['email'] ?? '',
        'address': contact['address'] ?? '',
      });
    });
    await _persistContacts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vet contact added successfully!')),
      );
    }
  }

  void _showEditVetDialog(int index, Map<String, dynamic> vet) {
    final nameController = TextEditingController(text: vet['name']);
    final phoneController = TextEditingController(text: vet['phone']);
    final emailController = TextEditingController(text: vet['email']);
    final addressController = TextEditingController(text: vet['address']);
    int? selectedPetId = vet['pet_id'] as int?;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Edit Vet Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _petDropdown(
                  selectedPetId: selectedPetId,
                  onChanged: (val) => setDialogState(() => selectedPetId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Vet Clinic Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BAEAE)),
              onPressed: () async {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() {
                    _vetContacts[index] = {
                      'vet_id': vet['vet_id'],
                      'pet_id': selectedPetId,
                      'name': nameController.text,
                      'phone': phoneController.text,
                      'email': emailController.text,
                      'address': addressController.text,
                    };
                  });
                  await _persistContacts();
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Vet contact updated successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in name and phone number')),
                  );
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteVetContact(int index) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Contact?'),
        content: Text('Are you sure you want to delete ${_vetContacts[index]['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _vetContacts.removeAt(index));
      await _persistContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vet contact deleted')),
        );
      }
    }
  }

  void _showAddVetDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    int? selectedPetId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Add Vet Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _petDropdown(
                  selectedPetId: selectedPetId,
                  onChanged: (val) => setDialogState(() => selectedPetId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vet Clinic Name',
                    hintText: 'e.g., Happy Paws Veterinary',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., 07123456789',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'e.g., contact@happypaws.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'e.g., 123 Paw Street, London',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BAEAE)),
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  _addVetContact({
                    'pet_id': selectedPetId,
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                    'address': addressController.text,
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in name and phone number')),
                  );
                }
              },
              child: const Text('Add Contact', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _petDropdown({required int? selectedPetId, required ValueChanged<int?> onChanged}) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Assign to pet (optional)',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedPetId,
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('No pet assigned')),
            ...widget.pets.map((pet) => DropdownMenuItem<int?>(
                  value: pet['pet_id'] as int,
                  child: Text(pet['pet_first_name'] as String),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        title: const Text('Household Vet Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8BAEAE), Color(0xFFB2D3C2), Color(0xFFE0F7F4)],
                ),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _vetContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.local_hospital_rounded, size: 80, color: Colors.white30),
                          SizedBox(height: 20),
                          Text(
                            'No vet contacts yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Add your vet clinic information to get started',
                            style: TextStyle(fontSize: 14, color: Colors.white60),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vetContacts.length,
                      itemBuilder: (context, index) {
                        final vet = _vetContacts[index];
                        final petId = vet['pet_id'] as int?;
                        final cardColor = _colorForPetId(petId);
                        final petName = _nameForPetId(petId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                  color: Colors.black.withValues(alpha: 0.1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_hospital_rounded, color: Color(0xFF0F6E56), size: 28),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vet['name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F6E56),
                                              ),
                                            ),
                                            if (petName.isNotEmpty)
                                              Text(petName, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        color: Colors.black,
                                        onPressed: () => _showEditVetDialog(index, vet),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red,
                                        onPressed: () => _deleteVetContact(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildContactRow(Icons.phone_rounded, vet['phone'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildContactRow(Icons.email_rounded, vet['email'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildContactRow(Icons.location_on_rounded, vet['address'] ?? 'N/A'),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVetDialog,
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        label: const Text('Add Vet Contact', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF185FA5), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VetContactsPage extends StatefulWidget {
  const VetContactsPage({super.key});

  @override
  State<VetContactsPage> createState() => _VetContactsPageState();
}

class _VetContactsPageState extends State<VetContactsPage> {
  List<Map<String, dynamic>> _vetContacts = [];
  bool _isLoading = true;
  final PetService _petService = PetService();

  @override
  void initState() {
    super.initState();
    _loadVetContactsFromAppointments();
  }

  Future<void> _loadVetContactsFromAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int ownerId = prefs.getInt('owner_id') ?? 0;

      // Fetch vet contacts from backend
      final vetList = await _petService.getOwnerVetContacts(ownerId);

      final vetContacts = <Map<String, dynamic>>[];
      for (var vet in vetList) {
        vetContacts.add({
          'vet_id': vet['vet_id'] ?? 0,
          'name': vet['clinic_name'] ?? '',
          'phone': vet['phone'] ?? '',
          'email': vet['email'] ?? '',
          'address': vet['address'] ?? '',
        });
      }

      if (mounted) {
        setState(() {
          _vetContacts = vetContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading vet contacts: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveVetContact(Map<String, String> contact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int ownerId = prefs.getInt('owner_id') ?? 0;

      final success = await _petService.createVetContact(
        ownerId: ownerId,
        clinicName: contact['name'] ?? '',
        phone: contact['phone'] ?? '',
        email: contact['email'] ?? '',
        address: contact['address'] ?? '',
      );

      if (success) {
        setState(() {
          _vetContacts.add({
            'vet_id': 0, // Will be assigned by backend
            'name': contact['name'] ?? '',
            'phone': contact['phone'] ?? '',
            'email': contact['email'] ?? '',
            'address': contact['address'] ?? '',
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vet contact added successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add vet contact')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving vet contact: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving vet contact')),
        );
      }
    }
  }

  void _showEditVetDialog(int index, Map<String, dynamic> vet) {
    final nameController = TextEditingController(text: vet['name']);
    final phoneController = TextEditingController(text: vet['phone']);
    final emailController = TextEditingController(text: vet['email']);
    final addressController = TextEditingController(text: vet['address']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Edit Vet Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Vet Clinic Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BAEAE),
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                final int ownerId = prefs.getInt('owner_id') ?? 0;

                debugPrint("DEBUG: Updating vet contact with ID: ${vet['vet_id']}");
                debugPrint("DEBUG: Clinic Name: ${nameController.text}");

                final success = await _petService.updateVetContact(
                  vetId: vet['vet_id'],
                  ownerId: ownerId,
                  clinicName: nameController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                  address: addressController.text,
                );

                debugPrint("DEBUG: Update success: $success");

                if (success && mounted) {
                  // Reload all vet contacts from the backend
                  await _loadVetContactsFromAppointments();
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vet contact updated successfully!')),
                  );
                } else if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update vet contact')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in name and phone number'),
                  ),
                );
              }
            },
            child: const Text(
              'Save Changes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteVetContact(int index, dynamic vetId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete ${_vetContacts[index]['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _petService.deleteVetContact(vetId);
      if (success) {
        setState(() {
          _vetContacts.removeAt(index);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vet contact deleted')),
          );
        }
      }
    }
  }

  void _showAddVetDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Add Vet Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BAEAE),
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                _saveVetContact({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'email': emailController.text,
                  'address': addressController.text,
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in name and phone number'),
                  ),
                );
              }
            },
            child: const Text(
              'Add Contact',
              style: TextStyle(color: Colors.white),
            ),
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
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        title: const Text(
          'Vet Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8BAEAE), Color(0xFFB2D3C2), Color(0xFFE0F7F4)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _vetContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_hospital_rounded,
                          size: 80,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No vet contacts yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Add your vet clinic information to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vetContacts.length,
                    itemBuilder: (context, index) {
                      final vet = _vetContacts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF5DCAA5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.1),
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
                                    const Icon(
                                      Icons.local_hospital_rounded,
                                      color: Color(0xFF0F6E56),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        vet['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F6E56),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      color: const Color(0xFF8BAEAE),
                                      onPressed: () => _showEditVetDialog(index, vet),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red,
                                      onPressed: () => _deleteVetContact(index, vet['vet_id']),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildContactRow(
                                  Icons.phone_rounded,
                                  vet['phone'] ?? 'N/A',
                                ),
                                const SizedBox(height: 8),
                                _buildContactRow(
                                  Icons.email_rounded,
                                  vet['email'] ?? 'N/A',
                                ),
                                const SizedBox(height: 8),
                                _buildContactRow(
                                  Icons.location_on_rounded,
                                  vet['address'] ?? 'N/A',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVetDialog,
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        label: const Text('Add Vet Contact'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF185FA5),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:maincode/services/pet_service.dart';
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
  final PetService _petService = PetService();

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
      final int ownerId = prefs.getInt('owner_id') ?? 0;
      final vetList = await _petService.getOwnerVetContacts(ownerId);

      final vetContacts = <Map<String, dynamic>>[];
      for (var vet in vetList) {
        vetContacts.add({
          'vet_id': vet['vet_id'] ?? 0,
          'pet_id': vet['pet_id'],
          'name': vet['clinic_name'] ?? '',
          'phone': vet['phone'] ?? '',
          'email': vet['email'] ?? '',
          'address': vet['address'] ?? '',
        });
      }

      // Auto-assign unassigned contacts to pets by position
      if (widget.pets.isNotEmpty) {
        for (int i = 0; i < vetContacts.length; i++) {
          if (vetContacts[i]['pet_id'] == null) {
            final pet = widget.pets[i % widget.pets.length];
            final petId = pet['pet_id'] as int;
            vetContacts[i]['pet_id'] = petId;
            await _petService.updateVetContact(
              vetId: vetContacts[i]['vet_id'],
              ownerId: ownerId,
              petId: petId,
              clinicName: vetContacts[i]['name'],
              phone: vetContacts[i]['phone'],
              email: vetContacts[i]['email'],
              address: vetContacts[i]['address'],
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _vetContacts = vetContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading vet contacts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVetContact(Map<String, dynamic> contact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int ownerId = prefs.getInt('owner_id') ?? 0;

      final success = await _petService.createVetContact(
        ownerId: ownerId,
        petId: contact['pet_id'] as int?,
        clinicName: contact['name'] ?? '',
        phone: contact['phone'] ?? '',
        email: contact['email'] ?? '',
        address: contact['address'] ?? '',
      );

      if (success) {
        await _loadVetContacts();
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
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final prefs = await SharedPreferences.getInstance();
                  final int ownerId = prefs.getInt('owner_id') ?? 0;

                  final success = await _petService.updateVetContact(
                    vetId: vet['vet_id'],
                    ownerId: ownerId,
                    petId: selectedPetId,
                    clinicName: nameController.text,
                    phone: phoneController.text,
                    email: emailController.text,
                    address: addressController.text,
                  );
                  if (success && mounted) {
                    await _loadVetContacts();
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Vet contact updated successfully!')),
                    );
                  } else if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _petService.deleteVetContact(vetId);
      if (success) {
        setState(() => _vetContacts.removeAt(index));
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BAEAE),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  _saveVetContact({
                    'pet_id': selectedPetId,
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
      ),
    );
  }

  Widget _petDropdown({
    required int? selectedPetId,
    required ValueChanged<int?> onChanged,
  }) {
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
        title: const Text(
          'Household Vet Contacts',
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
          Positioned(top: -40, left: -100, child: _backgroundCircle(350, Colors.white.withValues(alpha: 0.1))),
          Positioned(top: -20, left: -70, child: _backgroundCircle(370, Colors.white.withValues(alpha: 0.2))),
          Positioned(top: 10, left: -30, child: _backgroundCircle(340, Colors.white.withValues(alpha: 0.3))),
          Positioned(bottom: -40, right: -100, child: _backgroundCircle(350, Colors.white.withValues(alpha: 0.1))),
          Positioned(bottom: -20, right: -70, child: _backgroundCircle(370, Colors.white.withValues(alpha: 0.2))),
          Positioned(bottom: 10, right: -30, child: _backgroundCircle(340, Colors.white.withValues(alpha: 0.3))),
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
                              color: cardColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cardColor,
                                width: 2,
                              ),
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
                                      const Icon(
                                        Icons.local_hospital_rounded,
                                        color: Color(0xFF0F6E56),
                                        size: 28,
                                      ),
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
                                              Text(
                                                petName,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        color: Colors.white,
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

  Widget _backgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 30),
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

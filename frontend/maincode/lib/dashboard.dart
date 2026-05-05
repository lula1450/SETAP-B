import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:maincode/petinfo.dart';
import 'package:maincode/recentlylogged.dart';
import 'package:maincode/metrics.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:maincode/health_records.dart';
import 'package:maincode/report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/add_pet.dart';
import 'package:maincode/services/fun_fact_service.dart';
import 'package:maincode/feeding_schedule.dart';
import 'package:maincode/vet_contacts.dart';
import 'package:maincode/services/advice_service.dart';
import 'package:maincode/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maincode/widgets/app_drawer.dart';

class DashboardPage extends StatefulWidget {
  final int? initialPetId;
  const DashboardPage({super.key, this.initialPetId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedPetIndex = 0;
  final PetService _petService = PetService();
  List<dynamic> _pets = [];
  List<dynamic> _appointments = [];
  List<dynamic> _vetContacts = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  int? _selectedDay;

  final FunFactService _funFactService = FunFactService();
  String _dailyFact = "";

  final AdviceService _adviceService = AdviceService();
  String _dailyAdvice = "";

  void _updateDailyFact() {
    if (_pets.isNotEmpty) {
      final currentPet = _pets[_selectedPetIndex];
      setState(() {
        _dailyFact = _funFactService.getDailyFact(currentPet['species_id']);
      });
    }
  }

  void _updateDailyAdvice() async {
    if (_pets.isNotEmpty) {
      final currentPet = _pets[_selectedPetIndex];
      final petId = currentPet['pet_id'] as int;
      final breedId = currentPet['species_id'] as int;
      final prefs = await SharedPreferences.getInstance();
      final lastLogged = prefs.getString('last_logged_metric_$petId');
      String advice;
      if (lastLogged != null) {
        final parts = lastLogged.split('|');
        final metricName = parts[0];
        final value = parts.length > 1 ? parts[1] : '';
        final target = parts.length > 2 ? parts[2] : '';
        advice = _adviceService.getAdviceForLastMetric(breedId, metricName, value, target);
      } else {
        advice = _adviceService.getDailyAdvice(breedId);
      }
      if (mounted) setState(() => _dailyAdvice = advice);
    }
  }

  void _deleteAppointment(int appointmentId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete Appointment"),
        content: const Text("Are you sure you want to remove this visit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Just return true
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Call the service with the ID passed into the function
        await _petService.deleteAppointment(appointmentId);

        // 2. Refresh the UI by fetching the list again
        await _fetchAppointments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment removed successfully")),
          );
        }
      } catch (e) {
        debugPrint("Delete Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: Could not delete from server"),
            ),
          );
        }
      }
    }
  }

  void _editAppointment(dynamic appt) async {
    final notesController = TextEditingController(
      text: appt['appointment_notes'],
    );

    // Parse existing date
    DateTime appointmentDate = DateTime.parse(appt['pet_appointment_date']);

    // Parse existing time (assuming format "HH:mm:ss")
    final parts = appt['pet_appointment_time'].split(':');
    TimeOfDay initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    // Pick new date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return; // User cancelled date picker

    // Pick new time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      final selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (selectedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot update an appointment to a past date/time.")),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Edit Appointment"),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(hintText: "Notes"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BAEAE),
              ),
              onPressed: () async {
                String dateStr = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                String timeStr = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00";

                try {
                  await _petService.updateAppointment(
                    appointmentId: appt['pet_appointment_id'],
                    date: dateStr,
                    time: timeStr,
                    notes: notesController.text,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    _fetchAppointments();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Appointment updated!")),
                    );
                  }
                } catch (e) {
                  debugPrint("Update Error: $e");
                }
              },
              child: const Text(
                "Save Changes",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _setAppointmentReminder(dynamic appt) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (appt['reminder_time'] != null) {
      final parts = (appt['reminder_time'] as String).split(':');
      initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    int initialLeadDays = 1; // default: 1 day before
    if (appt['lead_days'] != null) {
      initialLeadDays = appt['lead_days'] as int;
    } else if (appt['repeat_type'] == 'Once') {
      initialLeadDays = 0;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ReminderDialog(
        initialTime: initial,
        initialLeadDays: initialLeadDays,
        appointmentDate: appt['pet_appointment_date'] as String,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        appt['reminder_enabled'] = true;
        appt['reminder_time'] = result['time'];
        appt['reminder_date'] = result['date'];
        appt['repeat_type'] = result['repeat'];
        appt['lead_days'] = result['lead_days'];
      });

      // Save reminder to SharedPreferences for sync with notifications page
      final prefs = await SharedPreferences.getInstance();
      final appointmentId = appt['pet_appointment_id'];
      await prefs.setString(
        "reminder_$appointmentId",
        jsonEncode({
          "enabled": true,
          "time": result['time'],
          "date": result['date'],
          "repeat": result['repeat'],
          "lead_days": result['lead_days'],
        }),
      );

      // Schedule notifications for both reminder and actual appointment time
      final notifService = NotificationService();
      
      // Schedule reminder notification
      final reminderParts = (result['time'] as String).split(':');
      final reminderDateParts = (result['date'] as String).split('-');
      final reminderDateTime = DateTime(
        int.parse(reminderDateParts[0]),
        int.parse(reminderDateParts[1]),
        int.parse(reminderDateParts[2]),
        int.parse(reminderParts[0]),
        int.parse(reminderParts[1]),
      );
      notifService.scheduleOnce(
        id: NotificationService.appointmentNotifId(appointmentId),
        title: 'Appointment Reminder',
        body: appt['appointment_notes'] ?? 'You have a vet appointment coming up!',
        dateTime: reminderDateTime,
      );

      // Schedule actual appointment notification
      final apptTimeParts = (appt['pet_appointment_time'] as String).split(':');
      final apptDateParts = (appt['pet_appointment_date'] as String).split('-');
      final apptDateTime = DateTime(
        int.parse(apptDateParts[0]),
        int.parse(apptDateParts[1]),
        int.parse(apptDateParts[2]),
        int.parse(apptTimeParts[0]),
        int.parse(apptTimeParts[1]),
      );
      notifService.scheduleOnce(
        id: NotificationService.appointmentNotifId(appointmentId) + 1000,
        title: 'Appointment Time',
        body: '${appt['appointment_notes'] ?? "Vet appointment"} is now!',
        dateTime: apptDateTime,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder updated!")),
      );
    }
  }

  void _deletePet(int petId, String petName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Remove $petName?"),
        content: Text(
          "Are you sure you want to delete $petName? This will also remove all their health records and appointments.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // You'll need to add this method to your PetService
        await _petService.deletePet(petId);

        if (mounted) {
          Navigator.pop(context); // Close the bottom sheet picker
          _fetchPets(); // Refresh the pet list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$petName removed successfully")),
          );
        }
      } catch (e) {
        debugPrint("Pet Delete Error: $e");
      }
    }
  }

  void _renamePetDialog(Map<String, dynamic> pet) async {
    final firstNameController = TextEditingController(text: pet['pet_first_name'] ?? '');
    final lastNameController = TextEditingController(text: pet['pet_last_name'] ?? '');
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Edit Pet Name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: "First Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: "Last Name (Optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newFirst = firstNameController.text.trim();
              if (newFirst.isEmpty) return;
              Navigator.pop(context);
              final success = await _petService.renamePet(
                pet['pet_id'],
                pet,
                newFirst,
                lastNameController.text.trim(),
              );
              if (success) {
                _fetchPets();
                messenger.showSnackBar(
                  SnackBar(content: Text("${pet['pet_first_name']} renamed to $newFirst")),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text("Failed to rename pet")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    firstNameController.dispose();
    lastNameController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().day;
    _fetchPets();
  }

  // --- LOGIC FUNCTIONS ---

  Future<void> _fetchPets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int ownerId = prefs.getInt('owner_id') ?? 0;
      final data = await _petService.getOwnerPets(ownerId);

      if (mounted) {
        if (data.isEmpty) {
          Future.delayed(Duration.zero, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPetPage()),
            ).then((_) => _fetchPets());
          });
        } else {
          setState(() {
            _pets = data;
            _isLoading = false;

            if (_pets.isNotEmpty) {
              if (widget.initialPetId != null) {
                final idx = _pets.indexWhere((p) => p['pet_id'] == widget.initialPetId);
                if (idx != -1) _selectedPetIndex = idx;
              }
              _updateDailyFact();
              _updateDailyAdvice();
            }
          });
          _fetchAppointments();
          _fetchVetContacts();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPetImage(int petId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 1. For now, let's keep using your service to save the path string
      // But we will also update the local state immediately so it shows up!
      bool success = await _petService.updatePetImage(petId, image.path);

      if (success) {
        setState(() {
          // We manually update the local list so the UI reacts instantly
          _pets[_selectedPetIndex]['pet_image_path'] = image.path;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Image updated!")));
      }
    }
  }

  Future<void> _fetchAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final int ownerId = prefs.getInt('owner_id') ?? 0;
    final appts = await _petService.getAllAppointments(ownerId);
    if (mounted) {
      setState(() {
        _appointments = appts;
      });
    }
  }

  Future<void> _fetchVetContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('vet_contacts');
      if (jsonStr != null && mounted) {
        setState(() {
          _vetContacts = jsonDecode(jsonStr) as List<dynamic>;
        });
      }
    } catch (e) {
      debugPrint("Error loading vet contacts: $e");
    }
  }

  List<Color> _getAppointmentColorsForDay(int day) {
    String dateString =
        "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    var dayAppts = _appointments.where(
      (a) => a['pet_appointment_date'] == dateString,
    );

    return dayAppts.map((appt) {
      int petIndex = _pets.indexWhere((p) => p['pet_id'] == appt['pet_id']);
      return _getPetColor(petIndex);
    }).toList();
  }

  bool _isToday(int day) {
    DateTime now = DateTime.now();
    return day == now.day &&
        _focusedDay.month == now.month &&
        _focusedDay.year == now.year;
  }

  void _showBookingDialog(int day) async {
    final notesController = TextEditingController();
    final vetController = TextEditingController();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      final selectedDateTime = DateTime(
        _focusedDay.year,
        _focusedDay.month,
        day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (selectedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot create an appointment in the past.")),
        );
        return;
      }

      int? selectedPetId = _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_id'] : null;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            // Build filtered vet list for current pet selection
            final Map<String, String> filteredVets = {};
            for (var vet in _vetContacts) {
              if (vet['pet_id'] == selectedPetId || vet['pet_id'] == null) {
                final name = (vet['clinic_name'] ?? vet['name'] ?? '') as String;
                if (name.isNotEmpty) filteredVets[name] = name;
              }
            }

            return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text("New Appointment: $day/${_focusedDay.month}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pet Selector
                if (_pets.length > 1) ...[
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Pet",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: DropdownButton<int>(
                      value: selectedPetId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text("Select pet"),
                      items: _pets.map<DropdownMenuItem<int>>((pet) {
                        return DropdownMenuItem<int>(
                          value: pet['pet_id'] as int,
                          child: Text(pet['pet_first_name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() {
                        selectedPetId = val;
                        vetController.clear();
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Quick-pick from saved contacts (only shown when contacts exist)
                if (filteredVets.isNotEmpty) ...[
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Vet Clinic",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: DropdownButton<String>(
                      value: filteredVets.containsKey(vetController.text) ? vetController.text : null,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text("Select from saved contacts"),
                      items: filteredVets.keys.map<DropdownMenuItem<String>>((name) {
                        return DropdownMenuItem<String>(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => vetController.text = val ?? ''),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Always-visible vet name field
                TextField(
                  controller: vetController,
                  decoration: const InputDecoration(
                    labelText: 'Vet / Clinic (optional)',
                    hintText: 'e.g. Happy Paws Veterinary',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(hintText: "Notes (optional)"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BAEAE)),
                onPressed: () async {
                  if (selectedPetId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a pet")),
                    );
                    return;
                  }

                  final vetName = vetController.text.trim();
                  final note = notesController.text.trim();
                  final String formattedNotes;
                  if (vetName.isNotEmpty && note.isNotEmpty) {
                    formattedNotes = "$vetName - $note";
                  } else if (vetName.isNotEmpty) {
                    formattedNotes = vetName;
                  } else {
                    formattedNotes = note;
                  }

                  String dateStr = "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                  String timeStr = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00";

                  await _petService.createAppointment(
                    petId: selectedPetId!,
                    date: dateStr,
                    time: timeStr,
                    notes: formattedNotes,
                  );

                  Navigator.pop(context);
                  _fetchAppointments();
                },
                child: const Text("Confirm", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
          },
        ),
      );
    }
  }

  Color _getPetColor(int index) {
    final List<Color> nameColors = [
      const Color.fromARGB(255, 146, 179, 236), // Blue
      const Color.fromRGBO(212, 162, 221, 1), // Purple
      const Color.fromARGB(255, 182, 139, 83), // Brown/Gold
      const Color.fromRGBO(223, 128, 158, 1), // Pink
      const Color.fromARGB(255, 126, 140, 224), // Indigo
      const Color.fromARGB(255, 255, 171, 145), // Coral
      const Color.fromARGB(255, 167, 235, 244), // Cyan
      const Color.fromARGB(255, 219, 247, 240), // Mint
    ];

    if (index < 0) return Colors.grey;
    return nameColors[index % nameColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        foregroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 120,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: _changePetButton(),
        ),
        leadingWidth: 90,
        title: _appBarTitle(),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8BAEAE), Color(0xFFB2D3C2), Color(0xFFE0F7F4)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _calendarSection(_getPetColor(_selectedPetIndex)),
              _buildDailySchedule(),
              _actionButtonsSection(context),
              _dailyInfoSection(),
              _navigationGridSection(
                _getPetColor(_selectedPetIndex),
                _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_first_name'] as String : '',
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailySchedule() {
    if (_selectedDay == null) return const SizedBox.shrink();

    String selectedDateStr =
        "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}";
    var dailyAppts = _appointments
        .where((a) => a['pet_appointment_date'] == selectedDateStr)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Household Schedule: $_selectedDay/${_focusedDay.month}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.black),
                onPressed: () => _showBookingDialog(_selectedDay!),
              ),
            ],
          ),
          if (dailyAppts.isEmpty)
            const Text(
              "No appointments today.",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            )
          else
            ...dailyAppts.map((appt) {
              int petIndex = _pets.indexWhere(
                (p) => p['pet_id'] == appt['pet_id'],
              );
              Color petColor = _getPetColor(petIndex);
              var pet = petIndex >= 0 ? _pets[petIndex] : null;
              String petName = pet != null ? pet['pet_first_name'] : "Pet";

              return Card(
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: petColor,
                    child: const Icon(
                      Icons.pets,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    "$petName: ${appt['appointment_notes'] ?? 'Vet Visit'}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    () {
                      final t = appt['pet_appointment_time'] as String;
                      final h = int.parse(t.substring(0, 2));
                      final min = t.substring(3, 5);
                      final period = h >= 12 ? 'pm' : 'am';
                      final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
                      return '$hour:$min$period';
                    }(),
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        onPressed: () => _editAppointment(appt),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.orange,
                          size: 18,
                        ),
                        onPressed: () => _setAppointmentReminder(appt),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        onPressed: () =>
                            _deleteAppointment(appt['pet_appointment_id']),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    int daysInMonth = DateUtils.getDaysInMonth(
      _focusedDay.year,
      _focusedDay.month,
    );
    DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    int firstWeekdayIndex = firstDayOfMonth.weekday % 7;
    List<String> months = [
      "JANUARY",
      "FEBRUARY",
      "MARCH",
      "APRIL",
      "MAY",
      "JUNE",
      "JULY",
      "AUGUST",
      "SEPTEMBER",
      "OCTOBER",
      "NOVEMBER",
      "DECEMBER",
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                  ),
                ),
              ),
              Text(
                "${months[_focusedDay.month - 1]} ${_focusedDay.year}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        _calendarHeaderRow(),
        const Divider(indent: 10, endIndent: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
            ),
            itemCount: daysInMonth + firstWeekdayIndex,
            itemBuilder: (context, index) {
              if (index < firstWeekdayIndex) return const SizedBox();
              int day = index - firstWeekdayIndex + 1;
              bool isToday = _isToday(day);
              bool isSelected = _selectedDay == day;
              List<Color> apptColors = _getAppointmentColorsForDay(day);

              return InkWell(
                onTap: () => setState(() => _selectedDay = day),
                onDoubleTap: () => _showBookingDialog(day),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(
                                color: const Color(0xFF8BAEAE),
                                width: 2,
                              )
                            : null,
                        color: isSelected
                            ? const Color(0xFF8BAEAE).withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          "$day",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    if (apptColors.isNotEmpty)
                      Positioned(
                        bottom: 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: apptColors
                              .map(
                                (color) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPetPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: _pets.length + 1,
        itemBuilder: (context, index) {
          if (index == _pets.length) {
            return ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("Add New Pet"),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPetPage()),
                );
                _fetchPets();
              },
            );
          }

          final pet = _pets[index]; // Reference current pet

          return ListTile(
            leading: Icon(Icons.pets, color: _getPetColor(index)),
            title: Text(pet['pet_first_name']),
            onTap: () {
              setState(() => _selectedPetIndex = index);
              _updateDailyFact();
              _updateDailyAdvice();
              Navigator.pop(context);
              _fetchAppointments();
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                    _renamePetDialog(pet);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    _deletePet(pet['pet_id'], pet['pet_first_name']);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _appBarTitle() {
    final currentPet = _pets.isNotEmpty ? _pets[_selectedPetIndex] : null;
    String petName = currentPet != null ? currentPet['pet_first_name'] : "Pet";

    // Get the image path from the pet data
    String? imagePath = currentPet?['pet_image_path'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () =>
              _pickPetImage(currentPet['pet_id']), // Function to pick image
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: (imagePath != null && imagePath.isNotEmpty)
                ? (imagePath.startsWith('http')
                    ? NetworkImage(imagePath.replaceFirst('http://localhost', 'http://10.0.2.2')) as ImageProvider
                    : FileImage(File(imagePath)))
                : null,
            child: (imagePath == null || imagePath.isEmpty)
                ? Icon(
                    Icons.add_a_photo,
                    size: 25,
                    color: _getPetColor(_selectedPetIndex),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLoading ? 'Loading...' : "$petName's Dashboard",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _changePetButton() {
    Color activePetColor = _pets.isNotEmpty
        ? _getPetColor(_selectedPetIndex)
        : const Color.fromARGB(255, 139, 174, 174);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RawMaterialButton(
          onPressed: () {
            if (_pets.isNotEmpty) _showPetPicker();
          },
          elevation: 4.0,
          fillColor: activePetColor,
          padding: const EdgeInsets.all(10.0),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.pets, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        const Text(
          "CHANGE",
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _calendarSection(Color petColor) {
    return SizedBox(
      height: 420,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          height: 380,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: CustomPaint(
                    painter: _PawPainter(color: Colors.white.withValues(alpha: 0.18), showBorder: false),
                  ),
                ),
              ),
              _buildCalendar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendarHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            .map(
              (day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _dailyInfoSection() {
    String petName = "your pet";
    if (_pets.isNotEmpty && _selectedPetIndex < _pets.length) {
      final selectedPet = _pets[_selectedPetIndex];
      petName = selectedPet['pet_first_name'] ?? "your pet";
    }
    final petColor = _getPetColor(_selectedPetIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          _infoBox("Daily fun fact for $petName:", _dailyFact, petColor),
          const SizedBox(height: 10),
          _infoBox("Advice for $petName:", _dailyAdvice, petColor),
        ],
      ),
    );
  }

  Widget _navigationGridSection(Color petColor, String petName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _reportPawButton(context, petColor),
          _gridButton(
            "$petName's\nHealth Records",
            petColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HealthRecordsPage(
                  petId: _pets[_selectedPetIndex]['pet_id'].toString(),
                  petName: _pets[_selectedPetIndex]['pet_first_name'] as String,
                  petImagePath: _pets[_selectedPetIndex]['pet_image_path'] as String?,
                ),
              ),
            ),
          ),
          _gridButton(
            "Household\nFeeding Schedule",
            petColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FeedingSchedulePage(),
              ),
            ),
          ),
          _gridButton(
            "Household\nVet Contacts",
            petColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VetContactsPage(pets: _pets, selectedPetIndex: _selectedPetIndex),
              ),
            ).then((_) => _fetchVetContacts()),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String content, Color petColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: petColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _gridButton(String label, Color petColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: petColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _actionButtonsSection(BuildContext context) {
    String currentPetName = _pets.isNotEmpty
        ? _pets[_selectedPetIndex]['pet_first_name']
        : "Pet";
    final petColor = _getPetColor(_selectedPetIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _logMetricPawButton(context, currentPetName, petColor),
          _actionButton(context, "$currentPetName's recently\nlogged data", petColor),
          _actionButton(context, "Find out\nmore about $currentPetName", petColor),
          _upcomingAppointmentButton(context, petColor),
        ],
      ),
    );
  }

  Widget _upcomingAppointmentButton(BuildContext context, Color petColor) {
    Map<String, dynamic>? next;

    if (_pets.isNotEmpty) {
      final currentPetId = _pets[_selectedPetIndex]['pet_id'];
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final upcoming = _appointments
          .where((a) =>
              a['pet_id'] == currentPetId &&
              a['appointment_status'] == 'Scheduled' &&
              (a['pet_appointment_date'] as String).compareTo(todayStr) >= 0)
          .toList();

      upcoming.sort((a, b) => (a['pet_appointment_date'] as String)
          .compareTo(b['pet_appointment_date'] as String));

      next = upcoming.isNotEmpty ? upcoming.first : null;
    }

    final petName = _pets.isNotEmpty
        ? _pets[_selectedPetIndex]['pet_first_name'] as String
        : '';

    String label;
    if (next != null) {
      final parts = (next['pet_appointment_date'] as String).split('-');
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = int.parse(parts[2]);
      final month = months[int.parse(parts[1]) - 1];
      label = "$petName\nAppt: $day $month";
    } else {
      label = "No upcoming\nappointment";
    }

    return InkWell(
      onTap: next == null
          ? null
          : () {
              final timeStr = next!['pet_appointment_time'] as String;
              final timeParts = timeStr.split(':');
              final hour = int.parse(timeParts[0]);
              final min = timeParts[1];
              final period = hour >= 12 ? 'pm' : 'am';
              final displayHour =
                  hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
              final notes = (next['appointment_notes'] as String?) ?? '';

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Next Appointment"),
                  content: Text(
                    "${next!['pet_appointment_date']}  $displayHour:$min$period"
                    "${notes.isNotEmpty ? '\n\n$notes' : ''}",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
      child: Container(
        width: 100,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: petColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 24,
              color: next != null ? const Color(0xFF8BAEAE) : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String text, Color petColor) {
    return InkWell(
      onTap: () {
        if (_pets.isEmpty) return; // Guard clause if data isn't loaded

        final currentPet = _pets[_selectedPetIndex];

        if (text.contains("Log")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MetricsPage(
                petId: currentPet['pet_id'],
                petName: currentPet['pet_first_name'],
                petIndex: _selectedPetIndex,
                petImagePath: currentPet['pet_image_path'] as String?,
              ),
            ),
          ).then((_) => _updateDailyAdvice());
        } else if (text.contains("recently")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecentlyLoggedDataPage(
                petId: currentPet['pet_id'],
                petName: currentPet['pet_first_name'],
                petImagePath: currentPet['pet_image_path'] as String?,
              ),
            ),
          );
        } else if (text.contains("Find out")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PetInfoPage(speciesId: currentPet['species_id']),
            ),
          );
        }
      },
      child: Container(
        width: 100,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: petColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _logMetricPawButton(BuildContext context, String petName, Color petColor) {
    return GestureDetector(
      onTap: () {
        if (_pets.isEmpty) return;
        final currentPet = _pets[_selectedPetIndex];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MetricsPage(
              petId: currentPet['pet_id'],
              petName: currentPet['pet_first_name'],
              petIndex: _selectedPetIndex,
              petImagePath: currentPet['pet_image_path'] as String?,
            ),
          ),
        ).then((_) => _updateDailyAdvice());
      },
      child: SizedBox(
        width: 100,
        height: 90,
        child: CustomPaint(
          painter: _PawPainter(color: petColor.withValues(alpha: 0.35)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(
                "Metrics",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportPawButton(BuildContext context, Color petColor) {
    return GestureDetector(
      onTap: () {
        if (_pets.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportsPage(
                petId: _pets[_selectedPetIndex]['pet_id'],
                petName: _pets[_selectedPetIndex]['pet_first_name'],
                petImagePath: _pets[_selectedPetIndex]['pet_image_path'] as String?,
              ),
            ),
          );
        } else {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPetPage()),
          ).then((_) => _fetchPets());
        }
      },
      child: SizedBox(
        width: 100,
        height: 90,
        child: CustomPaint(
          painter: _PawPainter(color: petColor.withValues(alpha: 0.35)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: const Text(
                "Report",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final int initialLeadDays;
  final String appointmentDate;

  const _ReminderDialog({
    required this.initialTime,
    required this.initialLeadDays,
    required this.appointmentDate,
  });

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late TimeOfDay _time;
  late int _leadDays;

  static const _leadOptions = [
    (label: 'On the day', days: 0),
    (label: '1 day before', days: 1),
    (label: '2 days before', days: 2),
    (label: '1 week before', days: 7),
  ];

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _leadDays = widget.initialLeadDays;
  }

  String _reminderDateStr() {
    final parts = widget.appointmentDate.split('-');
    final apptDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final reminderDate = apptDate.subtract(Duration(days: _leadDays));
    return '${reminderDate.year}-${reminderDate.month.toString().padLeft(2, '0')}-${reminderDate.day.toString().padLeft(2, '0')}';
  }

  String get _currentLabel =>
      _leadOptions.firstWhere((o) => o.days == _leadDays, orElse: () => _leadOptions[1]).label;

  @override
  Widget build(BuildContext context) {
    final timeLabel = _time.format(context);

    return AlertDialog(
      title: const Text('Set Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Reminder time'),
            trailing: Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _time);
              if (picked != null) setState(() => _time = picked);
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Remind me'),
            trailing: DropdownButton<int>(
              value: _leadDays,
              underline: const SizedBox(),
              items: _leadOptions
                  .map((o) => DropdownMenuItem(value: o.days, child: Text(o.label)))
                  .toList(),
              onChanged: (v) => setState(() => _leadDays = v!),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
              'date': _reminderDateStr(),
              'repeat': _currentLabel,
              'lead_days': _leadDays,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PawPainter extends CustomPainter {
  final Color color;
  final bool showBorder;
  _PawPainter({required this.color, this.showBorder = true});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Main pad
    final mainPad = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.68),
      width: size.width * 0.58,
      height: size.height * 0.44,
    );
    canvas.drawOval(mainPad, fill);
    if (showBorder) canvas.drawOval(mainPad, border);

    // 4 toe pads
    final toeW = size.width * 0.22;
    final toeH = size.height * 0.22;
    for (final center in [
      Offset(size.width * 0.18, size.height * 0.32),
      Offset(size.width * 0.38, size.height * 0.18),
      Offset(size.width * 0.62, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.32),
    ]) {
      final toe = Rect.fromCenter(center: center, width: toeW, height: toeH);
      canvas.drawOval(toe, fill);
      if (showBorder) canvas.drawOval(toe, border);
    }
  }

  @override
  bool shouldRepaint(_PawPainter old) => old.color != color || old.showBorder != showBorder;
}

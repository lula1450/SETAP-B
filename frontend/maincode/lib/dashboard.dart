import 'package:flutter/material.dart';
import 'package:maincode/login_page.dart';
import 'package:maincode/petinfo.dart';
import 'package:maincode/recentlylogged.dart';
import 'package:maincode/metrics.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:maincode/health_records.dart';
import 'package:maincode/report.dart';
import 'package:maincode/report_history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/add_pet.dart';
import 'package:maincode/edit_profile.dart';
import 'package:maincode/services/fun_fact_service.dart';
import 'package:maincode/feeding_schedule.dart';
import 'package:maincode/vet_contacts.dart';
import 'package:maincode/services/advice_service.dart';
import 'package:image_picker/image_picker.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedPetIndex = 0;
  final PetService _petService = PetService();
  List<dynamic> _pets = [];
  List<dynamic> _appointments = [];
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

  void _updateDailyAdvice() {
    if (_pets.isNotEmpty) {
      final currentPet = _pets[_selectedPetIndex];
      setState(() {
        _dailyAdvice = _adviceService.getDailyAdvice(currentPet['species_id']);
      });
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
        _fetchAppointments();

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
    );

    if (pickedTime != null && mounted) {
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
              _updateDailyFact();
              _updateDailyAdvice();
            }
          });
          _fetchAppointments(); // Fetch unified household schedule
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
    // Note: Ensure PetService has getAllAppointments(ownerId) implemented
    final appts = await _petService.getAllAppointments(ownerId);
    if (mounted) {
      setState(() {
        _appointments = appts;
      });
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
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("Vet Notes for $day/${_focusedDay.month}"),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(
              hintText: "e.g. Dr. Smith - Vaccinations",
            ),
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
                String dateStr =
                    "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                String timeStr =
                    "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00";

                await _petService.createAppointment(
                  petId: _pets[_selectedPetIndex]['pet_id'],
                  date: dateStr,
                  time: timeStr,
                  notes: notesController.text,
                );

                Navigator.pop(context);
                _fetchAppointments();
              },
              child: const Text(
                "Confirm",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
      endDrawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
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
              _calendarSection(),
              _buildDailySchedule(),
              _actionButtonsSection(context),
              _dailyInfoSection(),
              _navigationGridSection(),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF8BAEAE)),
                onPressed: () => _showBookingDialog(_selectedDay!),
              ),
            ],
          ),
          if (dailyAppts.isEmpty)
            const Text(
              "No appointments today.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    appt['pet_appointment_time'],
                    style: const TextStyle(fontSize: 10),
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
                  fontSize: 12,
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
                            ? const Color(0xFF8BAEAE).withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          "$day",
                          style: const TextStyle(fontSize: 10),
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
                                    horizontal: 0.5,
                                  ),
                                  width: 4,
                                  height: 4,
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
            // ADD THE DELETE ICON HERE
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () {
                // We'll define this function next
                _deletePet(pet['pet_id'], pet['pet_first_name']);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 139, 174, 174),
            ),
            child: Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _drawerTile(
            Icons.person,
            'Edit Profile',
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),
          _drawerTile(Icons.notifications, 'Notifications'),
          _drawerTile(
            Icons.palette,
            'Report History',
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportHistoryPage(),
                ),
              );
            },
          ),
          _drawerTile(
            Icons.logout,
            'Logout',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
          _drawerTile(
            Icons.delete_forever,
            'Delete Account',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    IconData icon,
    String title, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap:
          onTap ??
          () {
            if (title == 'Delete Account') {
              _showDeleteConfirmation();
            } else {
              Navigator.pop(context);
            }
          },
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
                ? NetworkImage(imagePath)
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
            color: Colors.white,
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
            color: Colors.white,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _calendarSection() {
    return SizedBox(
      height: 420, // Total height of the calendar stack
      child: Stack(
        children: [
          // --- TOP LEFT CLUSTER (Behind Calendar) ---
          // Top Left 1 (Largest, Most Transparent)
          Positioned(
            top: -10,
            left: -40,
            child: _backgroundCircle(200, Colors.white.withOpacity(0.1)),
          ),
          // Top Left 2 (Medium)
          Positioned(
            top: 10,
            left: -25,
            child: _backgroundCircle(190, Colors.white.withOpacity(0.2)),
          ),
          // Top Left 3 (Smallest, Most Visible)
          Positioned(
            top: 30,
            left: 10,
            child: _backgroundCircle(170, Colors.white.withOpacity(0.3)),
          ),

          // --- BOTTOM RIGHT CLUSTER (Behind Calendar) ---
          // Bottom Right 1 (Largest, Most Transparent)
          Positioned(
            bottom: -10,
            right: -40,
            child: _backgroundCircle(200, Colors.white.withOpacity(0.1)),
          ),
          // Bottom Right 2 (Medium)
          Positioned(
            bottom: 10,
            right: -25,
            child: _backgroundCircle(190, Colors.white.withOpacity(0.2)),
          ),
          // Bottom Right 3 (Smallest, Most Visible)
          Positioned(
            bottom: 30,
            right: 10,
            child: _backgroundCircle(170, Colors.white.withOpacity(0.3)),
          ),

          // --- THE MAIN CALENDAR CARD (Foreground) ---
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 380,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                // The slight opacity on the white container is key to seeing the rings
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildCalendar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
          .map(
            (day) => Text(
              day,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          )
          .toList(),
    );
  }

  Widget _dailyInfoSection() {
    String petName = "your pet";
    if (_pets.isNotEmpty && _selectedPetIndex < _pets.length) {
      final selectedPet = _pets[_selectedPetIndex];
      petName = selectedPet['pet_first_name'] ?? "your pet";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          _infoBox("Daily fun fact for $petName:", _dailyFact),
          const SizedBox(height: 10),
          _infoBox("Advice for $petName:", _dailyAdvice),
        ],
      ),
    );
  }

  Widget _navigationGridSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
        ),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 7,
          children: [
            _gridButton(
              "Generate\nreport",
              onTap: () {
                if (_pets.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportsPage(
                        petId: _pets[_selectedPetIndex]['pet_id'],
                        petName: _pets[_selectedPetIndex]['pet_first_name'],
                      ),
                    ),
                  );
                } else {
                  // No pet selected/available - send user to add a pet then refresh
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPetPage()),
                  ).then((_) => _fetchPets());
                }
              },
            ),
            _gridButton(
              "Health\nrecords",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HealthRecordsPage(),
                ),
              ),
            ),
            _gridButton(
              "Feeding\nschedule",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedingSchedulePage(),
                ),
              ),
            ),
            _gridButton(
              "Vet\ncontacts",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VetContactsPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _gridButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _backgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 20),
      ),
    );
  }

  void _showDeleteConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    final int ownerId = prefs.getInt('owner_id') ?? 0;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This will remove all your pets and appointments.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && ownerId != 0) {
      bool success = await _petService.deleteOwner(ownerId);
      if (success && mounted) {
        await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Could not delete account")),
        );
      }
    }
  }

  Widget _actionButtonsSection(BuildContext context) {
    // Get the name of the currently selected pet, default to "Pet" if list is empty
    String currentPetName = _pets.isNotEmpty
        ? _pets[_selectedPetIndex]['pet_first_name']
        : "Pet";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass the name to the helper
          _actionButton(context, "Log $currentPetName's daily\nmetrics"),
          _actionButton(context, "$currentPetName's recently\nlogged data"),
          _actionButton(context, "Find out\nmore about $currentPetName"),
          const Column(
            children: [
              Icon(
                Icons.sentiment_very_satisfied,
                size: 40,
                color: Colors.orange,
              ),
              Text("Current mood", style: TextStyle(fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String text) {
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
              ),
            ),
          );
        } else if (text.contains("recently")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecentlyLoggedDataPage(
                petId: currentPet['pet_id'],
                petName: currentPet['pet_first_name'],
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
        width: 90,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

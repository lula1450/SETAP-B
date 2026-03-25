import 'package:flutter/material.dart';
import 'package:maincode/petinfo.dart';
import 'package:maincode/recentlylogged.dart';
import 'package:maincode/metrics.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:maincode/health_records.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/add_pet.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedPetIndex = 0;
  final PetService _petService = PetService();
  List<dynamic> _pets = [];
  List<dynamic> _appointments = []; // NEW: Store appointments here
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  int? _selectedDay; // NEW: Track which day is tapped

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().day; // Default to today
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPetPage()))
            .then((_) => _fetchPets());
          });
        } else {
          setState(() {
            _pets = data;
            _isLoading = false;
          });
          _fetchAppointments(); // Fetch appointments for the first pet
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // NEW: Fetch appointments from FastAPI
  Future<void> _fetchAppointments() async {
    if (_pets.isEmpty) return;
    final petId = _pets[_selectedPetIndex]['pet_id'];
    final appts = await _petService.getAppointments(petId);
    if (mounted) {
      setState(() {
        _appointments = appts;
      });
    }
  }

  // NEW: Helper to check if a day has an appointment
  bool _hasAppointment(int day) {
    String dateString = "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    return _appointments.any((a) => a['pet_appointment_date'] == dateString);
  }

  bool _isToday(int day) {
    DateTime now = DateTime.now();
    return day == now.day && 
       _focusedDay.month == now.month && 
       _focusedDay.year == now.year;
  }

  // NEW: Booking Dialog for "Fake Vet"
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Vet Notes for $day/${_focusedDay.month}"),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(hintText: "e.g. Dr. Smith - Vaccinations"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BAEAE)),
              onPressed: () async {
                String dateStr = "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                String timeStr = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00";

                await _petService.createAppointment(
                  petId: _pets[_selectedPetIndex]['pet_id'],
                  date: dateStr,
                  time: timeStr,
                  notes: notesController.text,
                );
                
                Navigator.pop(context);
                _fetchAppointments(); // Refresh the dots!
              },
              child: const Text("Confirm", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Color _getPetColor(String name) {
    final List<Color> nameColors = [
      const Color.fromARGB(255, 146, 179, 236),
      const Color.fromRGBO(212, 162, 221, 1),
      const Color.fromARGB(255, 182, 139, 83),
      const Color.fromRGBO(223, 128, 158, 1),
      const Color.fromARGB(255, 219, 247, 240),
      const Color.fromARGB(255, 126, 140, 224),
      const Color.fromARGB(255, 255, 171, 145),
      const Color.fromARGB(255, 167, 235, 244),
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash += name.codeUnitAt(i);
    }
    return nameColors[hash % nameColors.length];
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
              _buildDailySchedule(), // NEW: List of appointments below calendar
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

  // --- NEW: DAILY SCHEDULE LIST ---
  Widget _buildDailySchedule() {
    if (_selectedDay == null) return const SizedBox.shrink();

    String selectedDateStr = "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}";
    var dailyAppts = _appointments.where((a) => a['pet_appointment_date'] == selectedDateStr).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Schedule: $_selectedDay/${_focusedDay.month}", style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF8BAEAE)), onPressed: () => _showBookingDialog(_selectedDay!)),
            ],
          ),
          if (dailyAppts.isEmpty)
            const Text("No appointments.", style: TextStyle(fontSize: 10, color: Colors.grey))
          else
            ...dailyAppts.map((appt) => Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.medical_services, size: 16, color: Colors.redAccent),
                title: Text(appt['appointment_notes'] ?? "Vet Visit", style: const TextStyle(fontSize: 12)),
                subtitle: Text(appt['pet_appointment_time'], style: const TextStyle(fontSize: 10)),
              ),
            )),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    int daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    int firstWeekdayIndex = firstDayOfMonth.weekday % 7;
    List<String> months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1))),
              Text("${months[_focusedDay.month - 1]} ${_focusedDay.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))),
            ],
          ),
        ),
        _calendarHeaderRow(),
        const Divider(indent: 10, endIndent: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 2),
            itemCount: daysInMonth + firstWeekdayIndex,
            itemBuilder: (context, index) {
  if (index < firstWeekdayIndex) return const SizedBox();
  int day = index - firstWeekdayIndex + 1;
  
  bool isToday = _isToday(day); // Uses your existing helper
  bool isSelected = _selectedDay == day;
  bool hasAppt = _hasAppointment(day);

  return InkWell(
    onTap: () => setState(() => _selectedDay = day),
    onDoubleTap: () => _showBookingDialog(day),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // The Background/Highlight Layer
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // 1. Highlight Today with a Border
            border: isToday 
                ? Border.all(color: const Color(0xFF8BAEAE), width: 2) 
                : null,
            // 2. Highlight Selected day with a Teal fill
            color: isSelected 
                ? const Color(0xFF8BAEAE).withOpacity(0.3) 
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              "$day",
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                // Make the text match the theme if it's today
                color: isToday ? const Color(0xFF8BAEAE) : Colors.black87,
              ),
            ),
          ),
        ),
        // 3. The Appointment Dot (Red)
        if (hasAppt)
          Positioned(
            bottom: 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
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

  // --- REFACTORED PICKER TO HANDLE REFRESH ---
  void _showPetPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPetPage()));
                _fetchPets();
              },
            );
          }
          return ListTile(
            leading: Icon(Icons.pets, color: _getPetColor(_pets[index]['pet_first_name'])),
            title: Text(_pets[index]['pet_first_name']),
            onTap: () {
              setState(() => _selectedPetIndex = index);
              Navigator.pop(context);
              _fetchAppointments(); // Update calendar when pet changes
            },
          );
        },
      ),
    );
  }

  // (All other helper functions like _appBarTitle, _drawerTile, etc. remain the same as your code)
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromARGB(255, 139, 174, 174)),
            child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _drawerTile(Icons.person, 'Edit Profile'),
          _drawerTile(Icons.notifications, 'Notifications'),
          _drawerTile(Icons.palette, 'Report History'),
          _drawerTile(Icons.logout, 'Logout'),
          _drawerTile(Icons.delete_forever, 'Delete Account', color: Colors.red),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        if (title == 'Delete Account') {
          _showDeleteConfirmation();
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _appBarTitle() {
    String petName = _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_first_name'] : "Pet";
    Color petColor = _pets.isNotEmpty ? _getPetColor(petName) : const Color.fromARGB(255, 139, 174, 174);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.pets, size: 20, color: petColor)),
        const SizedBox(height: 8),
        Text(_isLoading ? 'Loading...' : "$petName's Dashboard", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _changePetButton() {
    String petName = _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_first_name'] : "";
    Color activePetColor = _pets.isNotEmpty ? _getPetColor(petName) : const Color.fromARGB(255, 139, 174, 174);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RawMaterialButton(
          onPressed: () { if (_pets.isNotEmpty) _showPetPicker(); },
          elevation: 4.0,
          fillColor: activePetColor,
          padding: const EdgeInsets.all(10.0),
          shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
          child: const Icon(Icons.pets, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        const Text("CHANGE", style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _calendarSection() {
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _backgroundCircle(190, Colors.white.withOpacity(0.3))),
          Align(alignment: Alignment.bottomRight, child: _backgroundCircle(180, Colors.white.withOpacity(0.4))),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 380, width: double.infinity, margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
              child: _buildCalendar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarHeaderRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((day) => Text(day, style: const TextStyle(fontSize: 10, color: Colors.grey))).toList());
  }

  Widget _actionButtonsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(context, "Log daily\nmetrics"),
          _actionButton(context, "Recently\nlogged data"),
          _actionButton(context, "Find out\nmore about pet"),
          const Column(children: [Icon(Icons.sentiment_very_satisfied, size: 40, color: Colors.orange), Text("Current mood", style: TextStyle(fontSize: 8))]),
        ],
      ),
    );
  }

  Widget _dailyInfoSection() {
    String petName = _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_first_name'] : "your pet";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(children: [
        _infoBox("Daily fun fact:", "Pets can decrease stress!"),
        const SizedBox(height: 10),
        _infoBox("Advice:", "Ensure $petName gets 30 mins of play today.")
      ]),
    );
  }

  Widget _navigationGridSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)),
        child: GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 7,
          children: [
            _gridButton("Generate\nreport"),
            _gridButton("Health\nrecords", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthRecordsPage()))),
            _gridButton("Feeding\nschedule"),
            _gridButton("Surprise!"),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String text) {
    String petName = _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_first_name'] : "";
    return InkWell(
      onTap: () {
        if (text.contains("Log") && _pets.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MetricsPage(petId: _pets[_selectedPetIndex]['pet_id'], petName: _pets[_selectedPetIndex]['pet_first_name'])));
        } else if (text.contains("Recently")) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentlyLoggedDataPage()));
        } else if (text.contains("Find out")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetInfoPage(
                speciesId: _pets[_selectedPetIndex]['species_id'],
              ),
            ),
          );
        }
      },
      child: Container(
        width: 85, height: 85, alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
        child: Text(text.replaceAll("pet", petName), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _infoBox(String title, String content) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: Column(children: [Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(content, style: const TextStyle(fontSize: 10))]),
    );
  }

  Widget _gridButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
        child: Center(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _backgroundCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 20)));
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("Permanently delete profile and pet data?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: const Text("Delete", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
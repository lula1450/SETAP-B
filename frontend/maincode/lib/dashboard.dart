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
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPets();
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

  // Sum up the character codes of the name (e.g., 'A' = 65)
  int hash = 0;
  for (int i = 0; i < name.length; i++) {
    hash += name.codeUnitAt(i);
  }

  // Use the modulo operator (%) to pick a color from the list
  return nameColors[hash % nameColors.length];
}
  

  // Inside _DashboardPageState
Future<void> _fetchPets() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final int ownerId = prefs.getInt('owner_id') ?? 0;

    // Call backend
    final data = await _petService.getOwnerPets(ownerId);
    
    if (mounted) {
      if (data.isEmpty) {
        // Use a slight delay to ensure the Dashboard is ready before pushing the next page
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AddPetPage())
          ).then((_) => _fetchPets()); // Refresh when they come back from adding a pet
        });
      } else {
        setState(() {
          _pets = data;
          _isLoading = false;
        });
      }
    }
  } catch (e) {
    debugPrint("Error: $e");
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
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
      ),
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
            colors: [
              Color.fromARGB(255, 139, 174, 174),
              Color.fromARGB(255, 178, 211, 194),
              Color.fromARGB(255, 224, 247, 244),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _calendarSection(),
              _actionButtonsSection(context),
              _dailyInfoSection(),
              _navigationGridSection(),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER FUNCTIONS (ALL INSIDE CLASS) ---

  Widget _appBarTitle() {
    String petName = _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_first_name'] : "Pet";
    
    // Get the dynamic color for the current pet
    Color petColor = _pets.isNotEmpty 
        ? _getPetColor(petName) 
        : const Color.fromARGB(255, 139, 174, 174);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.add_a_photo, 
              size: 20, 
              color: petColor, // Dynamic color applied here!
            ),
          ),
        const SizedBox(height: 8),
        Text(
          _isLoading ? 'Loading...' : "${petName}'s Dashboard",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Delete Account?"),
      content: const Text(
        "This will permanently delete your profile and all associated pet data. This action cannot be undone.",
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Close the dialog
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            // TODO: Call your backend DELETE route here
            // Example: await _petService.deleteOwner(1);
            
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close drawer
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account successfully deleted")),
            );
          },
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  Widget _changePetButton() {
  // 1. Get the current active pet's name and color
  String petName = _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_first_name'] : "";
  Color activePetColor = _pets.isNotEmpty 
      ? _getPetColor(petName) 
      : const Color.fromARGB(255, 139, 174, 174);

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      RawMaterialButton(
        onPressed: () {
          if (_pets.isNotEmpty) _showPetPicker();
        },
        elevation: 4.0,
        // 2. Fill the button with the pet's unique color
        fillColor: activePetColor,
        padding: const EdgeInsets.all(10.0),
        // 3. CircleBorder creates the "pad" shape
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.pets, // The Paw Icon
          color: Colors.white,
          size: 24,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        "CHANGE",
        style: TextStyle(
          color: Colors.white, 
          fontSize: 7, 
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
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
      // Add +1 to the length to account for the "Add Pet" button
      itemCount: _pets.length + 1, 
      itemBuilder: (context, index) {
        // If it's the last item in the list, show the "Add New Pet" option
        if (index == _pets.length) {
          return ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.blueGrey),
            title: const Text(
              "Add New Pet",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            onTap: () async {
              Navigator.pop(context); // Close the bottom sheet
              
              final bool? wasAdded = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPetPage() ,)
              );
              if (wasAdded == true) {
                _fetchPets();
              }
            },
          );
        }

        // Otherwise, show the normal pet list tiles
        return ListTile(
          leading: Icon(
            Icons.pets, 
            color: _getPetColor(_pets[index]['pet_first_name']),
          ),
          title: Text(_pets[index]['pet_first_name']),
          trailing: _selectedPetIndex == index 
              ? const Icon(Icons.check, color: Colors.green) 
              : null,
          onTap: () {
            setState(() {
              _selectedPetIndex = index;
            });
            Navigator.pop(context);
          },
        );
      },
    ),
  );
}

  Widget _calendarSection() {
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _backgroundCircle(190, Colors.white.withValues(alpha: 0.3))),
          Align(alignment: Alignment.bottomRight, child: _backgroundCircle(180, Colors.white.withValues(alpha: 0.4))),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 380,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildCalendar(),
            ),
          ),
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
              return Center(child: Text("$day", style: const TextStyle(fontSize: 10)));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ElevatedButton(onPressed: () {}, child: const Text("CREATE appointment", style: TextStyle(fontSize: 10))),
        ),
      ],
    );
  }

  Widget _calendarHeaderRow() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            .map((day) => Text(day, style: const TextStyle(fontSize: 10, color: Colors.grey)))
            .toList());
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
          const Column(children: [Icon(Icons.sentiment_very_dissatisfied, size: 40, color: Colors.orange), Text("Current mood", style: TextStyle(fontSize: 8))]),
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
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
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
            _gridButton("Generate\nreport"),
            _gridButton("Health\nrecords", onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthRecordsPage()));}),
            _gridButton("Feeding\nschedule"),
            _gridButton("Surprise!"),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String text) {
    String petName = _pets.isNotEmpty ? _pets[_selectedPetIndex]['pet_first_name'] : "";

    String buttontext = text.replaceAll("pet", petName);
    
    return InkWell(
      onTap: () {
        // 1. Log daily metrics - Needs pet details
        if (text.contains("Log")) {
          if (_pets.isNotEmpty) {
            final currentPet = _pets[_selectedPetIndex]; // Define inside the logic block
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MetricsPage(
                  petId: currentPet['pet_id'],
                  petName: currentPet['pet_first_name'],
                ),
              ),
            );
          } else {
            // Safety check in case Lauren hasn't added a pet yet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please add a pet first!")),
            );
          }
        } 
        
        // 2. Recently logged data
        else if (text.contains("Recently")) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecentlyLoggedDataPage()),
          );
        } 
        
        // 3. Find out more about pet
        else if (text.contains("Find out")) {
          if (_pets.isNotEmpty) {
            final currentPet = _pets[_selectedPetIndex];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PetInfoPage(
                  speciesId: currentPet['species_id'],
                )
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please add pet!")),
            );
          }
        }
      },
      child: Container(
        width: 85,
        height: 85,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
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

  Widget _infoBox(String title, String content) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: Column(children: [
        Center(child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Center(child: Text(content, style: const TextStyle(fontSize: 10))),
      ]),
    );
  }

  Widget _gridButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
        child: Center(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _backgroundCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 20)));
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
}
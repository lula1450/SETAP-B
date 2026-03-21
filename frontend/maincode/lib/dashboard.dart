import 'package:flutter/material.dart';
import 'package:maincode/petinfo.dart';
import 'package:maincode/recentlylogged.dart';
import 'metrics.dart';
import 'package:maincode/services/pet_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PetService _petService = PetService();
  List<dynamic> _pets = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    try {
      final data = await _petService.getOwnerPets(1);
      setState(() {
        _pets = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching pets: $e");
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
        leadingWidth: 70,
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
    String petName = _pets.isNotEmpty ? _pets[0]['pet_first_name'] : "Pet";
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.add_a_photo, size: 20, color: Color.fromARGB(255, 139, 174, 174))),
        const SizedBox(height: 8),
        Text(
          _isLoading ? 'Loading...' : '$petName Dashboard',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _changePetButton() {
    return TextButton(
      onPressed: () {
        if (_pets.isNotEmpty) _showPetPicker();
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      child: const Text("Change\nPet",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8, color: Color.fromARGB(255, 139, 174, 174), fontWeight: FontWeight.bold)),
    );
  }

  void _showPetPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: _pets.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.pets, color: Color.fromARGB(255, 139, 174, 174)),
          title: Text(_pets[index]['pet_first_name']),
          onTap: () => Navigator.pop(context),
        ),
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
    String petName = _pets.isNotEmpty ? _pets[0]['pet_first_name'] : "your pet";
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
            _gridButton("Health\nrecords"),
            _gridButton("Feeding\nschedule"),
            _gridButton("Surprise!"),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String text) {
    return InkWell(
      onTap: () {
        if (text.contains("Log")) Navigator.push(context, MaterialPageRoute(builder: (context) => const MetricsPage()));
        if (text.contains("Recently")) Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentlyLoggedDataPage()));
        if (text.contains("Find out")) Navigator.push(context, MaterialPageRoute(builder: (context) => const PetInfoPage()));
      },
      child: Container(
        width: 85, height: 85, alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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

  Widget _gridButton(String label) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
      child: Center(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
    );
  }

  Widget _backgroundCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 20)));
  }

  Widget _drawerTile(IconData icon, String title) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: () => Navigator.pop(context));
  }
}
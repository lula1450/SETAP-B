import 'package:flutter/material.dart';
import 'package:maincode/petinfo.dart';
import 'package:maincode/recentlylogged.dart';
import 'metrics.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The endDrawer creates the sidebar that slides from the right
  endDrawer: Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Color.fromARGB(255, 139, 174, 174)),
          child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Edit Profile'),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Report History'),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () => Navigator.pop(context),
        ),
      ],
    ),
  ),

      // AppBar styled with the ARGB Top Color
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        elevation: 0,
        toolbarHeight: 120,
        centerTitle: true,
        // 1. Move "Change Pet" to the top left
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: TextButton(
            onPressed: () {
              print("Change Pet triggered"); // Logic Tier hook for switching pets
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 4), // Ensures the button is large enough for text
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "Change\nPet",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: Color.fromARGB(255, 139, 174, 174), fontWeight: FontWeight.bold),
            ),
          ),
        ),
        leadingWidth: 70,
         // Gives the button enough room to display text

        // 2. Centered Profile Pic and Title remains the same
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.add_a_photo, 
                size: 20, 
                color: Color.fromARGB(255, 139, 174, 174)
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Snuggles Dashboard', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ],
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Vertical ARGB Ombre Background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 139, 174, 174), // Top
              Color.fromARGB(255, 178, 211, 194), // Middle
              Color.fromARGB(255, 224, 247, 244), // Bottom
            ],
          ),
        ),
        child: SingleChildScrollView( 
          child: Column(
            children: [
              
              SizedBox(
                height: 400, 
                child: Stack(
                  children: [
                    // TOP LEFT CIRCLES
                    Align(
                      alignment: Alignment.topLeft,
                      child: Stack(
                        children: [
                          _backgroundCircle(190, Colors.white.withOpacity(0.3)),
                          _backgroundCircle(170, Colors.white.withOpacity(0.2)),
                          _backgroundCircle(180, Colors.white.withOpacity(0.4)),
                        ],
                      ),
                    ),

                    // BOTTOM RIGHT CIRCLES
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _backgroundCircle(190, Colors.white.withOpacity(0.3)),
                          _backgroundCircle(170, Colors.white.withOpacity(0.2)),
                          _backgroundCircle(180, Colors.white.withOpacity(0.4)),
                        ],
                      ),
                    ),

                    // CENTERED CALENDAR CONTAINER
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 350,
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildCalendar(),
                      ),
                    ),
                  ],
                ),
              ),
              

              // 2. Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [ 
                    _actionButton(context, "Log daily\nmetrics"), 
                    _actionButton(context, "Recently\nlogged data"),
                    _actionButton(context, "Find out\nmore about pet"),
                    const Column(
                      children: [
                        Icon(Icons.sentiment_very_dissatisfied, size: 40, color: Colors.orange),
                        Text("Current mood", style: TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Daily Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Column(
                  children: [
                    _infoBox("Daily fun fact:", "Pets can decrease stress!"),
                    const SizedBox(height: 10),
                    _infoBox("Advice:", "Ensure Snuggles gets 30 mins of play today."),
                  ],
                ),
              ),

              // 4. Navigation Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 7,
                padding: const EdgeInsets.all(16),
                children: [
                  _gridButton("Generate\nreport"),
                  _gridButton("Health\nrecords"),
                  _gridButton("Feeding\nschedule"),
                  _gridButton("Press me for a surprise"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  // HELPER FUNCTIONS

  Widget _actionButton(BuildContext context, String text) {
    return InkWell(
      onTap: () {
        if (text == "Log daily\nmetrics") {
          // Navigate to MetricsPage
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MetricsPage()));
        }
        if (text == "Recently\nlogged data") {
          // Navigate to RecentlyLoggedDataPage
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentlyLoggedDataPage()));
        }
        if (text == "Find out\nmore about pet") {
          // Navigate to PetInfoPage
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PetInfoPage()));
        }
        // Functionality to be added later
      },
      child: Container(
        width: 85,
        height: 85,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5), // Maintains the frosted look
          borderRadius: BorderRadius.circular(15), // This adds the rounded edges
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

  Widget _gridButton(String label) {
    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Center(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(content, style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // Helper to create the ombre-colored rings
  Widget _backgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 20), // Creates the ring effect
      ),
    );
    // --- ADD THIS TO THE BOTTOM OF YOUR CLASS ---
    }
  // --- ADD THIS TO THE BOTTOM OF YOUR CLASS ---
  Widget _buildCalendar() {
    DateTime now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    int firstWeekdayIndex = firstDayOfMonth.weekday % 7; // Adjust for Sunday start

    List<String> months = [
      "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
      "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size:20),
                onPressed: () => setState (() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                }),
              ),
              Text("${months[_focusedDay.month - 1]} ${_focusedDay.year}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.chevron_right, size:20),
                onPressed: () => setState (() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                }),
              ),


              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 204, 213).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("PETSYNC CALENDAR", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
              .map((day) => Text(day, style: const TextStyle(fontSize: 10, color: Colors.grey)))
              .toList(),
        ),
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
              
              int dayNumber = index - firstWeekdayIndex + 1;
              bool isToday = dayNumber == now.day;

              return Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isToday ? const Color.fromARGB(255, 139, 174, 174).withOpacity(0.4) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$dayNumber",
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("CREATE appointment", style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }
}
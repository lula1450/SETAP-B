import 'package:flutter/material.dart';
import 'package:maincode/petinfo.dart';
import 'package:maincode/recentlylogged.dart';
import 'metrics.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
        toolbarHeight: 120, // Increased height for the stacked image and text
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => print("Trigger photo upload"), // Future Logic Tier hook
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.add_a_photo, size: 30, color: Color.fromARGB(255, 139, 174, 174)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Snuggles Dashboard', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
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
                height: 300, 
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
                        height: 250,
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text("Calendar Widget Area")),
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
                  _gridButton("Change\nPet"),
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
  }
} // Final bracket fixes compilation error

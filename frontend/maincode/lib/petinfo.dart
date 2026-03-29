import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/pet_info_service.dart';
import 'package:maincode/edit_profile.dart';

class PetInfoPage extends StatelessWidget {
  final int speciesId;

  const PetInfoPage({super.key, this.speciesId = 1});

  @override
  Widget build(BuildContext context) {
    final petInfo = PetInfoService().getPetInfo(speciesId);

    final Map<String, IconData> cardIcons = {
      "Breed Info": Icons.pets,
      "Care Tips": Icons.health_and_safety,
      "Personality": Icons.emoji_emotions,
      "Diet": Icons.restaurant_menu,
      "Potential Health Issues": Icons.local_hospital,
      "Preferred Environment": Icons.park,
    };

    return Scaffold(
      endDrawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BAEAE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pet Information',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8BAEAE),
              Color(0xFFB2D3C2),
              Color(0xFFE0F7F4),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  petInfo["image"],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      petInfo["name"],
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      petInfo["traits"],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final Uri url = Uri.parse(petInfo["helpUrl"]);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: Text(
                  "General Help Guide",
                  style: TextStyle(
                    color: Colors.blue[800],
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildCard(
                          "Breed Info", petInfo["breedInfo"], cardIcons)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildCard(
                          "Care Tips", petInfo["careTips"], cardIcons)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildCard(
                          "Personality", petInfo["personality"], cardIcons)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildCard("Diet", petInfo["diet"], cardIcons)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildCard("Potential Health Issues",
                          petInfo["health"] ?? [], cardIcons)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildCard("Preferred Environment",
                          petInfo["environment"] ?? [], cardIcons)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List items, Map<String, IconData> icons) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Solid white cards
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icons[title], color: Colors.blue[800]),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map<Widget>((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(item),
              )),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration:
                BoxDecoration(color: Color.fromARGB(255, 139, 174, 174)),
            child: Text('Settings',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _drawerTile(context, Icons.person, 'Edit Profile', onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()));
          }),
          _drawerTile(context, Icons.notifications, 'Notifications'),
          _drawerTile(context, Icons.palette, 'Report History'),
          _drawerTile(context, Icons.logout, 'Logout'),
          _drawerTile(context, Icons.delete_forever, 'Delete Account',
              color: Colors.red),
        ],
      ),
    );
  }

  ListTile _drawerTile(BuildContext context, IconData icon, String title,
      {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap ??
          () {
            if (title == 'Delete Account') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Account?"),
                  content:
                      const Text("Permanently delete profile and pet data?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
    );
  }
}
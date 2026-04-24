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

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _cardItem("Breed Info", petInfo["breedInfo"], cardIcons, context),
                  _cardItem("Care Tips", petInfo["careTips"], cardIcons, context),
                  _cardItem("Personality", petInfo["personality"], cardIcons, context),
                  _cardItem("Diet", petInfo["diet"], cardIcons, context),
                  _cardItem("Potential Health Issues", petInfo["health"] ?? [], cardIcons, context),
                  _cardItem("Preferred Environment", petInfo["environment"] ?? [], cardIcons, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardItem(String title, List items, Map<String, IconData> icons, BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 48) / 2;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icons[title], color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map<Widget>(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item.toString(),
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF8BAEAE)),
            child: Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _drawerTile(context, Icons.person, 'Edit Profile', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfilePage(),
              ),
            );
          }),
          _drawerTile(context, Icons.notifications, 'Notifications'),
          _drawerTile(context, Icons.history, 'Report History'),
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
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}
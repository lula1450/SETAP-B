import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pet_info_service.dart';
import 'package:maincode/widgets/app_drawer.dart';

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
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BAEAE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pet Information',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  petInfo["image"],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 250,
                      color: const Color(0xFFB2D3C2),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stack) => Container(
                    height: 250,
                    color: const Color(0xFFB2D3C2),
                    child: const Icon(Icons.pets, size: 60, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final Uri url = Uri.parse(petInfo["helpUrl"]);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
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
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoButton("Breed Info", petInfo["breedInfo"], cardIcons, context),
                  _buildInfoButton("Care Tips", petInfo["careTips"], cardIcons, context),
                  _buildInfoButton("Personality", petInfo["personality"], cardIcons, context),
                  _buildInfoButton("Diet", petInfo["diet"], cardIcons, context),
                  _buildInfoButton("Potential Health Issues", petInfo["health"] ?? [], cardIcons, context),
                  _buildInfoButton("Preferred Environment", petInfo["environment"] ?? [], cardIcons, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoButton(String title, List items, Map<String, IconData> icons, BuildContext context) {
    return FilledButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(icons[title], color: Colors.blue[800]),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: items.map<Widget>((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    "• $item",
                    style: const TextStyle(fontSize: 14),
                  ),
                )).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      icon: Icon(icons[title]),
      label: Text(title),
    );
  }
}
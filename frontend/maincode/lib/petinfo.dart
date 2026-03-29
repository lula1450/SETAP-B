import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/pet_info_service.dart';

class PetInfoPage extends StatelessWidget {
  final int speciesId;

  const PetInfoPage({super.key, this.speciesId = 1});

  @override
  Widget build(BuildContext context) {
    final petInfo = PetInfoService().getPetInfo(speciesId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BAEAE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pet Information',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFDFF9F7),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // image
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

              // name
              Center(
                child: Column(
                  children: [
                    Text(
                      petInfo["name"],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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

              // general help url
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

              // breed info + care tips
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCard(
                      "Breed Info",
                      petInfo["breedInfo"],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      "Care Tips",
                      petInfo["careTips"],
                      color: Colors.blue[50],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // personality + diet
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCard(
                      "Personality",
                      petInfo["personality"],
                      color: Colors.blue[50],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      "Diet",
                      petInfo["diet"],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // health
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCard(
                      "Potential Health Issues",
                      petInfo["health"] ?? [],
                      color: Colors.red[50],
                    ),
                  ),
                  //environment
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      "Preffered Environment",
                      petInfo["environment"] ?? [],
                      color: Colors.green[50],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // card layout
  Widget _buildCard(String title, List items, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map<Widget>((item) => Text(item)).toList(),
        ],
      ),
    );
  }
}
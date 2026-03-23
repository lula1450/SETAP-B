import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PetInfoPage extends StatelessWidget {
  const PetInfoPage({super.key});

  final String helpUrl =
      "https://www.golden-retriever-owners.co.uk/info-guides/general-care-and-welfare-advice";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
              // Page title
              const Center(
                child: Text(
                  "Find out more about your pet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Profile card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: _cardStyle(),
                child: const Text(
                  "Golden Retriever Profile Card",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              // URL 
              GestureDetector(
                onTap: () async {
                  final Uri url = Uri.parse(helpUrl);
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
              // Two-column section: Info and Care tips
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: _cardStyle(),
                      child: const Text(
                        "Golden Retriever\n\n"
                        "Size: Large\n"
                        "Lifespan: 10-12 Years\n"
                        "Energy level: High\n"
                        "Trainability: *****",
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: _cardStyle(color: Colors.blue[50]),
                      child: const Text(
                        "Care tips\n"
                        ".....",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Two-column section: Behaviour and Diet
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: _cardStyle(),
                      child: const Center(
                          child: Text(
                        "Behaviour\nProcess",
                        textAlign: TextAlign.center,
                      )),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: _cardStyle(),
                      child: const Center(
                          child: Text(
                        "Diet\nProcess",
                        textAlign: TextAlign.center,
                      )),
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

  BoxDecoration _cardStyle({Color? color}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black12),
    );
  }
}
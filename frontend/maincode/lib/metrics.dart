import 'package:flutter/material.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  final List<String> _metrics = [
    "Weight",
    "Stool Quality",
    "Energy Level",
    "Appetite",
    "Water Intake",
    "Litter Box Usage",
    "Grooming Frequency",
    "Vomit Events",
  ];

  final Set<String> _favorites = {};

  void _toggleFavorite(String title) {
    setState(() {
      if (_favorites.contains(title)) {
        _favorites.remove(title);
      } else {
        _favorites.add(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedMetrics = List.from(_metrics);
    sortedMetrics.sort((a, b) {
      if (_favorites.contains(a) && !_favorites.contains(b)) return -1;
      if (!_favorites.contains(a) && _favorites.contains(b)) return 1;
      return 0;
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        title: const Text('Snuggles Metrics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
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
        child: Stack( // Use Stack to keep background circles behind the content
          children: [
            // BACKGROUND DECORATION
            _buildBackgroundDecorations(),

            // MAIN CONTENT
            Column(
              children: [
                // 1. Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'SEARCH BAR',
                      hintStyle: const TextStyle(fontSize: 12),
                      fillColor: Colors.white.withOpacity(0.9),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // 2. Metrics List
                Expanded( // Expanded works here because it is inside a Column
                  child: ListView.builder(
                    itemCount: sortedMetrics.length,
                    itemBuilder: (context, index) {
                      String title = sortedMetrics[index];
                      String goal = _getGoalText(title);

                      return _metricRow(
                        context,
                        title,
                        "Current\nLevel",
                        goal,
                        _favorites.contains(title),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for background rings
  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
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
        Align(
          alignment: Alignment.bottomRight,
          child: Stack(
            children: [
              _backgroundCircle(190, Colors.white.withOpacity(0.4)),
              _backgroundCircle(170, Colors.white.withOpacity(0.2)),
              _backgroundCircle(180, Colors.white.withOpacity(0.3)),
            ],
          ),
        ),
      ],
    );
  }

  String _getGoalText(String title) {
    if (title == "Weight") return "Goal (kg)";
    if (title == "Stool Quality" || title == "Energy Level") return "Goal (high,\nmed, low)";
    if (title == "Appetite") return "Goal (High,\nMed, Low)";
    if (title == "Water Intake") return "Goal (ml)";
    return "Goal";
  }

  Widget _backgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 25),
      ),
    );
  }

  Widget _metricRow(BuildContext context, String title, String current, String goal, bool isFavorite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton( // Favorite toggle
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : Colors.white70,
            ),
            onPressed: () => _toggleFavorite(title),
          ),
          Expanded(flex: 3, child: _metricButton(title, Colors.white.withOpacity(0.8), () => _showEditDialog(context, title))),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(current, const Color(0xFFD6EAF8).withOpacity(0.9), () {})),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(goal, const Color(0xFFFEF9E7).withOpacity(0.9), () {})),
        ],
      ),
    );
  }

  Widget _metricButton(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Log $title"),
        content: const Text("Use the options below to increase or decrease the current value."),
        actions: [
          IconButton(icon: const Icon(Icons.remove), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Save")),
        ],
      ),
    );
  }
}
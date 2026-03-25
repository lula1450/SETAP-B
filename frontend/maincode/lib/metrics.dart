import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MetricsPage extends StatefulWidget {
  final int petId;
  final String petName;

  const MetricsPage({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  final HealthService _healthService = HealthService();
  Map<String, Map<String, String>> _latestValues = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<String> _metrics = [
    "Weight", "Stool Quality", "Energy Level", "Appetite", "Water Intake",
    "Litter Box Usage", "Grooming Frequency", "Vomit Events", "Feather Condition",
    "Wing Strength", "Perch Activity", "Vocalisation Level", "Basking Time",
    "Shedding Quality", "Humidity Level", "Stool pellets", "Chewing Behaviour",
    "Wheel Activity"
  ];

  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _refreshAllMetrics();
  }

  @override
  void didUpdateWidget(covariant MetricsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the petId changed, reload everything for the new pet
    if (oldWidget.petId != widget.petId) {
      _loadFavorites();
      _refreshAllMetrics();
    }
  }

  Future<void> _refreshAllMetrics() async {
    setState(() => _latestValues = {});
    for (var metric in _metrics) {
      String backendName = metric.toLowerCase().replaceAll(" ", "_");
      Map<String, String> data = await _healthService.getLatestMetricData(widget.petId, backendName);
      if (mounted) {
        setState(() => _latestValues[metric] = data);
      }
    }
  }

  // Load favorites specifically for THIS pet
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Key is now unique, e.g., "favorites_1"
      _favorites = prefs.getStringList('favorites_${widget.petId}') ?? [];
    });
  }

  // Save favorites specifically for THIS pet
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites_${widget.petId}', _favorites);
  }

  void _toggleFavorite(String title) {
    setState(() {
      if (_favorites.contains(title)) {
        _favorites.remove(title);
      } else {
        _favorites.add(title);
      }
    });
    _saveFavorites();
  }

  Color _getPetColor(String name) {
    // 1. Exact same color list as Dashboard
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

    // 2. Exact same "Clean & Hash" math as Dashboard
    final String cleanName = name.trim().toLowerCase();
    int hash = 0;
    for (int i = 0; i < cleanName.length; i++) {
      hash += cleanName.codeUnitAt(i);
    }

    // 3. Modulo based on the NEW list length (8)
    return nameColors[hash % nameColors.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGoalText(String title) {
    if (title == "Weight") return "Goal (kg)";
    if (title == "Water Intake") return "Goal (ml)";
    if (["Stool Quality", "Energy Level", "Appetite"].contains(title)) return "Goal (Level)";
    return "Goal";
  }

  void _showEditDialog(BuildContext context, String title) {
    final TextEditingController valueController = TextEditingController();
    final TextEditingController goalController = TextEditingController();
    bool isLogging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text("Log $title"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(labelText: "Current $title", hintText: "e.g. 4.5"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: goalController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(labelText: "Target Goal (Optional)", hintText: "e.g. 5.0"),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              isLogging 
                ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      if (valueController.text.isEmpty && goalController.text.isEmpty) return;
                      setDialogState(() => isLogging = true);
                      String backendName = title.toLowerCase().replaceAll(" ", "_");

                      try {
                        if (valueController.text.isNotEmpty) {
                          await _healthService.logMetric(
                            petId: widget.petId,
                            metricName: backendName,
                            value: valueController.text,
                          );
                        }
                        if (goalController.text.isNotEmpty) {
                          await _healthService.syncGoalToBackend(
                            widget.petId, 
                            backendName, 
                            goalController.text
                          );
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          _refreshAllMetrics();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Updated $title successfully!"), backgroundColor: Colors.green.shade700),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setDialogState(() => isLogging = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving data")));
                        }
                      }
                    }, 
                    child: const Text("Save")
                  ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color petThemeColor = _getPetColor(widget.petName);
    List<String> filteredMetrics = _metrics.where((m) => m.toLowerCase().contains(_searchQuery)).toList();
    
    filteredMetrics.sort((a, b) {
      if (_favorites.contains(a) && !_favorites.contains(b)) return -1;
      if (!_favorites.contains(a) && _favorites.contains(b)) return 1;
      return 0;
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        toolbarHeight: 120,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Column(
          children: [
            CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.pets, size: 25, color: petThemeColor)),
            const SizedBox(height: 8),
            Text("${widget.petName}'s Metrics", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8BAEAE), Color(0xFFB2D3C2), Color(0xFFE0F7F4)]),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search Metrics...', 
                  fillColor: Colors.white.withOpacity(0.9), 
                  filled: true, 
                  prefixIcon: const Icon(Icons.search), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)
                ),
              ),
            ),
            
            // --- NEW COLUMN HEADERS ---
            Padding(
              padding: const EdgeInsets.only(left: 65.0, right: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox()), // Space above Metric Title
                  Expanded(
                    flex: 1, 
                    child: Text("Current", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1, 
                    child: Text("Target", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: filteredMetrics.length,
                itemBuilder: (context, index) {
                  String title = filteredMetrics[index];
                  String currentVal = _latestValues[title]?['value'] ?? "...";
                  String targetVal = _latestValues[title]?['target'] ?? "";
                  String goalDisplay = targetVal.isNotEmpty ? targetVal : _getGoalText(title);
                  return _metricRow(context, title, currentVal, goalDisplay, _favorites.contains(title));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(BuildContext context, String title, String current, String goal, bool isFavorite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? Colors.amber : Colors.white70), onPressed: () => _toggleFavorite(title)),
          Expanded(flex: 3, child: _metricButton(title, Colors.white.withOpacity(0.8), () => _showEditDialog(context, title))),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(current, const Color(0xFFD6F8F8), () {})),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(goal, const Color(0xFFEDFEE7), () {})),
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
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class HealthService {
  static const String baseUrl = "http://127.0.0.1:8000"; 

  Future<Map<String, dynamic>> logMetric({required int petId, required String metricName, required dynamic value}) async {
    final url = Uri.parse("$baseUrl/health/log");
    var formattedValue = double.tryParse(value.toString()) ?? value.toString();
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"pet_id": petId, "metric_name": metricName, "value": formattedValue}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, String>> getLatestMetricData(int petId, String metricName) async {
    final url = Uri.parse("$baseUrl/health/latest?pet_id=$petId&metric_name=$metricName");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"value": data['value']?.toString() ?? "---", "target": data['target']?.toString() ?? ""};
      }
    } catch (_) {}
    return {"value": "---", "target": ""};
  }

  Future<void> syncGoalToBackend(int petId, String metricName, String goal) async {
    final uri = Uri.parse("$baseUrl/health/goal").replace(queryParameters: {
      "pet_id": petId.toString(),
      "metric_name": metricName,
      "goal": goal,
    });
    final response = await http.post(uri);
    if (response.statusCode != 200) throw Exception("Failed to sync goal");
  }
}
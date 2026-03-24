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

  // Local storage for values from the backend
  Map<String, String> _latestValues = {};

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
    _refreshAllMetrics(); // Fetch backend data immediately on start
  }

  // Refreshes the "Current Level" for all metrics in the list
  Future<void> _refreshAllMetrics() async {
  setState(() {
    _latestValues = {}; // Clear the map to trigger shimmer loading
  });

  for (var metric in _metrics) {
    String backendName = metric.toLowerCase().replaceAll(" ", "_");
    String val = await _healthService.getLatestMetric(widget.petId, backendName);
    
    if (mounted) {
      setState(() {
        _latestValues[metric] = val; // This replaces shimmer with the value
      });
    }
  }
}

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favoriteMetrics') ?? [];
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteMetrics', _favorites);
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredMetrics = _metrics
        .where((metric) => metric.toLowerCase().contains(_searchQuery))
        .toList();

    filteredMetrics.sort((a, b) {
      if (_favorites.contains(a) && !_favorites.contains(b)) return -1;
      if (!_favorites.contains(a) && _favorites.contains(b)) return 1;
      return 0;
    });

    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 139, 174, 174)),
              child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(leading: const Icon(Icons.person), title: const Text('Edit Profile'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.notifications), title: const Text('Notifications'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.palette), title: const Text('Report History'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        elevation: 0,
        toolbarHeight: 120,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.add_a_photo, size: 20, color: Color.fromARGB(255, 139, 174, 174)),
            ),
            SizedBox(height: 8),
            Text(
              "${widget.petName}'s Metrics", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ],
        ),
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
        child: Stack(
          children: [
            _buildBackgroundDecorations(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'SEARCH BAR',
                      fillColor: Colors.white.withValues(alpha: 0.9),
                      filled: true,
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredMetrics.length,
                    itemBuilder: (context, index) {
                      String title = filteredMetrics[index];
                      return _metricRow(
                        context,
                        title,
                        _latestValues[title] ?? "...", // Fix: titile -> title
                        _getGoalText(title),
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

  // --- UI Helpers ---

  String _getGoalText(String title) {
    if (title == "Weight") return "Goal (kg)";
    if (title == "Stool Quality" || title == "Energy Level") return "Goal (high,\nmed, low)";
    if (title == "Appetite") return "Goal (High,\nMed, Low)";
    if (title == "Water Intake") return "Goal (ml)";
    return "Goal";
  }

  void _showEditDialog(BuildContext context, String title) {
    final TextEditingController valueController = TextEditingController();
    bool isLogging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text("Log $title"),
            content: TextField(
              controller: valueController,
              keyboardType: title == "Weight" || title == "Water Intake"
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text, 
              decoration: const InputDecoration(hintText: "e.g. 4.5 or lethargic"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              isLogging
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (valueController.text.isEmpty) return;
                        setDialogState(() => isLogging = true);

                        String backendMetricName = title.toLowerCase().replaceAll(" ", "_");
                        final result = await _healthService.logMetric(
                          petId: widget.petId,
                          metricName: backendMetricName,
                          value: valueController.text,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          _refreshAllMetrics(); // Update UI with the new data
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['analysis'] ?? result['error']),
                              backgroundColor: const Color.fromARGB(255, 139, 174, 174),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text("Save"),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricRow(BuildContext context, String title, String current, String goal, bool isFavorite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? Colors.amber : Colors.white70),
            onPressed: () => _toggleFavorite(title),
          ),
          Expanded(flex: 3, child: _metricButton(title, Colors.white.withValues(alpha: 0.8), () => _showEditDialog(context, title))),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(current, const Color.fromARGB(255, 214, 248, 248).withValues(alpha: 0.9), () {})),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(goal, const Color.fromARGB(255, 237, 254, 231).withValues(alpha: 0.9), () {})),
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

  Widget _buildBackgroundDecorations() {
    return Container(); // Placeholder for your circle decorations
  }
}

// --- SERVICES ---

class HealthService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS
  static const String baseUrl = "http://127.0.0.1:8000"; 

  Future<Map<String, dynamic>> logMetric({
    required int petId,
    required String metricName,
    required dynamic value,
    String? notes,
  }) async {
    final url = Uri.parse("$baseUrl/health/log");
    
    // IMPORTANT: Ensure the value is handled based on the backend Union[float, int, str]
    // If it's a number, try to send it as a number, otherwise a string.
    var formattedValue = double.tryParse(value.toString()) ?? value.toString();

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pet_id": petId,
          "metric_name": metricName, // Must match Python MetricName Enum exactly
          "value": formattedValue,
          "notes": notes ?? "Logged from Flutter",
        }),
      );

      debugPrint("Backend Response Status: ${response.statusCode}");
      debugPrint("Backend Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // This will help you see if it's a 422 (Validation Error) or 500 (Crash)
        return {"error": "Server returned ${response.statusCode}", "analysis": "Check backend console"};
      }
    } catch (e) {
      debugPrint("Flutter Connection Error: $e");
      return {"error": "Connection failed"};
    }
  }

  Future<String> getLatestMetric(int petId, String metricName) async {
    // Your backend uses Query Parameters: ?pet_id=1&metric_name=weight
    final url = Uri.parse("$baseUrl/health/latest?pet_id=$petId&metric_name=$metricName");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // In your Python code, if no record exists, you return {"value": "---"}
        return data['value'].toString();
      }
      return "---";
    } catch (e) {
      return "Err";
    }
  }
}

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLoading({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      onEnd: () {}, // Optional: can trigger reverse if needed
    );
  }
}
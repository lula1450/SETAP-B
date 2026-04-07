import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MetricsPage extends StatefulWidget {
  final int petId;
  final String petName;
  final int petIndex;

  const MetricsPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.petIndex,
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

  // --- NEW: UNIT MAPPING LOGIC ---
  String _getUnitForMetric(String metricName) {
    final name = metricName.toLowerCase().trim();
    switch (name) {
      case "weight": return "kg";
      case "water intake": return "ml";
      case "basking time":
      case "wheel activity": return "mins";
      case "humidity level": return "%";
      case "stool pellets":
      case "vomit events": return "count";
      case "stool quality":
      case "energy level":
      case "appetite":
      case "vocalisation level":
      case "wing strength":
      case "feather condition":
      case "perch activity":
      case "shedding quality":
      case "chewing behaviour": return "/5"; // Scale 1-5
      default: return "";
    }
  }

  String _getGoalText(String title) {
    final unit = _getUnitForMetric(title);
    return unit.isNotEmpty ? "Goal ($unit)" : "Goal";
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

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favorites_${widget.petId}') ?? [];
    });
  }

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

  Color _getPetColor(int index) {
    final List<Color> nameColors = [
      const Color.fromARGB(255, 146, 179, 236), // Blue
      const Color.fromRGBO(212, 162, 221, 1),   // Purple
      const Color.fromARGB(255, 182, 139, 83),   // Brown/Gold
      const Color.fromRGBO(223, 128, 158, 1),   // Pink
      const Color.fromARGB(255, 126, 140, 224), // Indigo
      const Color.fromARGB(255, 255, 171, 145), // Coral
      const Color.fromARGB(255, 167, 235, 244), // Cyan
      const Color.fromARGB(255, 219, 247, 240), // Mint
    ];
    
    if (index < 0) return Colors.grey;
    return nameColors[index % nameColors.length];
  }

  void _showEditDialog(BuildContext context, String title) {
    final TextEditingController valueController = TextEditingController();
    final TextEditingController goalController = TextEditingController();
    final String unit = _getUnitForMetric(title);
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Current $title", 
                    hintText: "e.g. 4.5",
                    suffixText: unit,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: goalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Target Goal", 
                    hintText: "e.g. 5.0",
                    suffixText: unit,
                  ),
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
                        setDialogState(() => isLogging = false);
                        debugPrint("Save error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving data: $e")));
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

  Color _getStatusColor(String current, String target) {
    if (current == "---" || target.isEmpty) return Colors.transparent;
    try {
      double c = double.parse(current.replaceAll(RegExp(r'[^0-9\.]'), ''));
      double t = double.parse(target.replaceAll(RegExp(r'[^0-9\.]'), ''));
      if (t == 0) return Colors.transparent;
      double diff = (c - t).abs() / t;

      // If the value is more than 15% off target, show Amber/Orange
      if (diff > 0.15) return Colors.orangeAccent;
      // Otherwise, use the PetSync Teal
      return const Color(0xFF8BAEAE);
    } catch (_) {
      return Colors.transparent;
    }
  }

  Widget _buildSparkline(Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: CustomPaint(
        size: const Size(35, 20),
        painter: _SparklinePainter(color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color petThemeColor = _getPetColor(widget.petIndex);
    List<String> filteredMetrics = _metrics.where((m) => m.toLowerCase().contains(_searchQuery)).toList();
    
    filteredMetrics.sort((a, b) {
      if (_favorites.contains(a) && !_favorites.contains(b)) return -1;
      if (!_favorites.contains(a) && _favorites.contains(b)) return 1;
      return 0;
    });

    return Scaffold(
      endDrawer: _buildDrawer(),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search Metrics...',
                  fillColor: Colors.white.withValues(alpha: 0.9),
                  filled: true,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 65.0, right: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox()),
                  Expanded(flex: 1, child: Text("Current", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]))),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: Text("Target", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]))),
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
                  return _metricRow(context, title, currentVal, targetVal, _favorites.contains(title));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(BuildContext context, String title, String current, String target, bool isFavorite) {
    final String unit = _getUnitForMetric(title);
    
    // 2. Calculate Status Color
    Color statusColor = _getStatusColor(current, target);

    String displayCurrent = (current == "..." || current == "---") ? current : "$current $unit";
    String displayGoal = target.isNotEmpty ? "$target $unit" : _getGoalText(title);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border, 
              color: isFavorite ? Colors.amber : Colors.white.withValues(alpha: 0.7)), 
            onPressed: () => _toggleFavorite(title)
          ),
          // Main Metric Name Button
          Expanded(
            flex: 3, 
            child: _metricButton(
              title, 
              Colors.white.withValues(alpha: 0.8), 
              () => _showEditDialog(context, title),
              borderColor: statusColor, // Pass the status color here
              showSpark: true,          // Enable the sparkline here
            )
          ),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(displayCurrent, const Color.fromARGB(123, 249, 249, 249), () => _showEditDialog(context, title))),
          const SizedBox(width: 8),
          // 3. QUICK LOG SHORTCUT (The Target column now also opens the log)
          Expanded(flex: 1, child: _metricButton(displayGoal, const Color.fromARGB(82, 255, 255, 255), () => _showEditDialog(context, title))),
        ],
      ),
    );
  }

  Widget _metricButton(String text, Color color, VoidCallback onTap, {Color borderColor = Colors.transparent, bool showSpark = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          // Applying the Status Border
          border: Border.all(
            color: borderColor != Colors.transparent ? borderColor : Colors.black12,
            width: borderColor != Colors.transparent ? 2.5 : 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Positioning the Mini Sparkline on the right
            if (showSpark && borderColor != Colors.transparent)
              Positioned(right: 5, child: _buildSparkline(borderColor)),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Settings Drawer (copied from Dashboard) ---
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromARGB(255, 139, 174, 174)),
            child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _drawerTile(Icons.person, 'Edit Profile'),
          _drawerTile(Icons.notifications, 'Notifications'),
          _drawerTile(Icons.palette, 'Report History'),
          _drawerTile(Icons.logout, 'Logout'),
          _drawerTile(Icons.delete_forever, 'Delete Account', color: Colors.red),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        if (title == 'Delete Account') {
          _showDeleteConfirmation();
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("Permanently delete profile and pet data?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: const Text("Delete", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (color == Colors.transparent) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // This creates a fake "trending up" little squiggle
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.8);
    path.lineTo(size.width * 0.5, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    if (response.statusCode != 200) {
      throw Exception("Failed to log metric: ${response.statusCode} - ${response.body}");
    }
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
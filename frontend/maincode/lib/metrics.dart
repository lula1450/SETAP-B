import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maincode/widgets/app_drawer.dart';

class MetricsPage extends StatefulWidget {
  final int petId;
  final String petName;
  final int petIndex;
  final String? petImagePath;

  const MetricsPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.petIndex,
    this.petImagePath,
  });

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  final HealthService _healthService = HealthService();
  Map<String, Map<String, String>> _latestValues = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  List<String> _metrics = [];
  List<String> _customMetricNames = [];
  bool _loadingMetrics = true;
  Map<String, String> _customUnits = {};
  List<String> _favorites = [];
  String? _lastLoggedMetric;

  // Metrics where setting a target doesn't make clinical sense
  static const _noTargetMetrics = {
    'Vomit Events',
    'Stool Quality',
    'Stool Pellets',
    'Shedding Quality',
  };

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadMetricsThenRefresh();
  }

  Future<void> _loadMetricsThenRefresh() async {
    final fetched = await _healthService.getAvailableMetrics(widget.petId);
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('custom_metrics_${widget.petId}') ?? [];
    final hidden = prefs.getStringList('hidden_metrics_${widget.petId}') ?? [];
    final unitsRaw = prefs.getString('custom_units_${widget.petId}') ?? '{}';
    final unitsMap = Map<String, String>.from(jsonDecode(unitsRaw) as Map);
    final lastLogged = prefs.getString('last_logged_metric_${widget.petId}');
    final lastLoggedTitle = lastLogged?.split('|').first;
    if (mounted) {
      setState(() {
        _customMetricNames = List<String>.from(custom);
        _metrics = [
          ...custom,
          ...fetched.map(_toDisplayName).where((m) => !hidden.contains(m)),
        ];
        _customUnits = unitsMap;
        _loadingMetrics = false;
        if (lastLoggedTitle != null && lastLoggedTitle.isNotEmpty) {
          _lastLoggedMetric = lastLoggedTitle;
        }
      });
      _refreshAllMetrics();
    }
  }

  Future<void> _removeMetric(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('custom_metrics_${widget.petId}') ?? [];

    if (custom.contains(name)) {
      custom.remove(name);
      await prefs.setStringList('custom_metrics_${widget.petId}', custom);
      final updatedUnits = Map<String, String>.from(_customUnits)..remove(name);
      await prefs.setString('custom_units_${widget.petId}', jsonEncode(updatedUnits));
      final key = name.toLowerCase().replaceAll(" ", "_");
      await prefs.remove('custom_current_${widget.petId}_$key');
      await prefs.remove('custom_target_${widget.petId}_$key');
      await prefs.remove('custom_history_${widget.petId}_$key');
      setState(() {
        _customUnits = updatedUnits;
        _customMetricNames.remove(name);
      });
    } else {
      final hidden = prefs.getStringList('hidden_metrics_${widget.petId}') ?? [];
      if (!hidden.contains(name)) {
        hidden.add(name);
        await prefs.setStringList('hidden_metrics_${widget.petId}', hidden);
      }
    }

    setState(() {
      _metrics.remove(name);
      _favorites.remove(name);
      _latestValues.remove(name);
    });

    _saveFavorites();
  }

  Future<void> _addCustomMetric() async {
    final nameController = TextEditingController();
    const unitOptions = ["kg", "ml", "mins", "%", "/5", "count", "none"];
    String selectedUnit = "none";

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Add Custom Metric"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: "e.g. Sleep Duration"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedUnit,
                decoration: const InputDecoration(labelText: "Unit"),
                items: unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setDialogState(() => selectedUnit = v ?? "none"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                "name": nameController.text.trim(),
                "unit": selectedUnit,
              }),
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    final name = result?["name"] ?? "";
    final unit = result?["unit"] ?? "none";
    if (name.isEmpty || _metrics.contains(name)) return;

    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('custom_metrics_${widget.petId}') ?? [];
    custom.add(name);
    await prefs.setStringList('custom_metrics_${widget.petId}', custom);

    final updatedUnits = Map<String, String>.from(_customUnits)..[name] = unit;
    await prefs.setString('custom_units_${widget.petId}', jsonEncode(updatedUnits));

    setState(() {
      _customUnits = updatedUnits;
      _customMetricNames.insert(0, name);
      _metrics.insert(0, name);
    });
  }

  void _showDeleteMetricDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Remove a Metric"),
          content: SizedBox(
            width: double.maxFinite,
            child: _metrics.isEmpty
                ? const Text("No metrics to remove.")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _metrics.length,
                    itemBuilder: (_, i) {
                      final name = _metrics[i];
                      return ListTile(
                        title: Text(name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            _removeMetric(name);
                            setDialogState(() {});
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Done")),
          ],
        ),
      ),
    );
  }

  String _toDisplayName(String backendName) {
    return backendName.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  // --- NEW: UNIT MAPPING LOGIC ---
  String _getUnitForMetric(String metricName) {
    final name = metricName.toLowerCase().trim();
    switch (name) {
      case "weight":           return "kg";
      case "water intake":     return "ml/day";
      case "basking time":     return "mins/day";
      case "wheel activity":   return "mins/day";
      case "humidity level":   return "%";
      case "litter box usage": return "x/day";
      case "grooming frequency": return "x/day";
      case "vomit events":     return "x/day";
      case "stool pellets":    return "pellets/day";
      case "stool quality":    return "/5";
      case "energy level":     return "/5";
      case "appetite":         return "/5";
      case "vocalisation level": return "/5";
      case "wing strength":    return "/5";
      case "feather condition": return "/5";
      case "perch activity":   return "/5";
      case "shedding quality": return "/5";
      case "chewing behaviour": return "/5";
      default: return _customUnits[metricName] == "none" ? "" : (_customUnits[metricName] ?? "");
    }
  }


  void _checkAndWarnDeviation(BuildContext ctx, String title, String enteredValue, String targetValue) async {
    final current = double.tryParse(enteredValue);
    final target = double.tryParse(targetValue);
    if (current == null || target == null || target == 0) return;

    final deviation = (current - target).abs() / target;
    if (deviation <= 0.15) return;

    final unit = _getUnitForMetric(title);
    final isAbove = current > target;
    final percent = (deviation * 100).toStringAsFixed(0);

    if (!ctx.mounted) return;
    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text("$title Alert", style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(
          "$title is $percent% ${isAbove ? 'above' : 'below'} the target of $targetValue $unit.\n\nConsider speaking to your vet if this continues.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text("Dismiss")),
        ],
      ),
    );
  }

  Future<void> _refreshAllMetrics() async {
    setState(() => _latestValues = {});
    final prefs = await SharedPreferences.getInstance();
    for (var metric in _metrics) {
      if (_customMetricNames.contains(metric)) {
        final key = metric.toLowerCase().replaceAll(" ", "_");
        final value = prefs.getString('custom_current_${widget.petId}_$key') ?? '---';
        final target = prefs.getString('custom_target_${widget.petId}_$key') ?? '';
        final histRaw = prefs.getString('custom_history_${widget.petId}_$key') ?? '[]';
        String time = '';
        try {
          final hist = jsonDecode(histRaw) as List;
          if (hist.isNotEmpty) time = (hist.first as Map)['time']?.toString() ?? '';
        } catch (_) {}
        if (mounted) setState(() => _latestValues[metric] = {'value': value, 'target': target, 'time': time});
      } else {
        final backendName = metric.toLowerCase().replaceAll(" ", "_");
        final data = await _healthService.getLatestMetricData(widget.petId, backendName);
        if (mounted) setState(() => _latestValues[metric] = data);
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

  void _showInfoDialog(BuildContext ctx, String title) {
    final String unit = _getUnitForMetric(title);
    final String currentVal = _latestValues[title]?['value'] ?? '---';
    final String targetVal = _latestValues[title]?['target'] ?? '';
    final String lastTime = _latestValues[title]?['time'] ?? '';
    final String entryId = _latestValues[title]?['id'] ?? '';
    final bool hasTarget = !_noTargetMetrics.contains(title);
    final bool neverLogged = currentVal == '---' || currentVal == '...';
    final bool isCustom = _customMetricNames.contains(title);
    final String key = title.toLowerCase().replaceAll(' ', '_');

    Future<void> clearCurrent(BuildContext dlgCtx) async {
      final confirmed = await showDialog<bool>(
        context: dlgCtx,
        builder: (confirmCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Remove latest entry?'),
          content: Text(
            'The most recent log entry for $title will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(confirmCtx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (dlgCtx.mounted) Navigator.pop(dlgCtx);
      bool success = false;
      if (isCustom) {
        final prefs = await SharedPreferences.getInstance();
        final histKey = 'custom_history_${widget.petId}_$key';
        final histRaw = prefs.getString(histKey) ?? '[]';
        final entries = List<Map<String, dynamic>>.from(
          (jsonDecode(histRaw) as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        if (entries.isNotEmpty) {
          entries.sort((a, b) => (b['time'] ?? '').toString().compareTo((a['time'] ?? '').toString()));
          entries.removeAt(0);
          await prefs.setString(histKey, jsonEncode(entries));
          if (entries.isEmpty) {
            await prefs.remove('custom_current_${widget.petId}_$key');
          } else {
            await prefs.setString('custom_current_${widget.petId}_$key', jsonEncode(entries.first));
          }
        }
        success = true;
      } else if (entryId.isNotEmpty) {
        success = await _healthService.deleteEntry(widget.petId, int.parse(entryId));
      }
      if (mounted) {
        _refreshAllMetrics();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Current value cleared.' : 'Could not clear value.'),
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade400,
        ));
      }
    }

    Future<void> clearTarget(BuildContext dlgCtx) async {
      Navigator.pop(dlgCtx);
      bool success = false;
      if (isCustom) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('custom_target_${widget.petId}_$key');
        success = true;
      } else {
        success = await _healthService.clearGoal(widget.petId, key);
      }
      if (mounted) {
        _refreshAllMetrics();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Target cleared.' : 'Could not clear target.'),
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade400,
        ));
      }
    }

    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow(
              Icons.monitor_heart_outlined, "Current",
              neverLogged ? 'Not yet logged' : '$currentVal $unit',
              onClear: neverLogged ? null : () => clearCurrent(dlgCtx),
            ),
            if (!neverLogged && lastTime.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.access_time, "Last logged", lastTime),
            ],
            if (hasTarget) ...[
              const SizedBox(height: 12),
              _infoRow(
                Icons.flag_outlined, "Target",
                targetVal.isEmpty ? 'Not set' : '$targetVal $unit',
                onClear: targetVal.isEmpty ? null : () => clearTarget(dlgCtx),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text("Close")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              _showEditDialog(ctx, title, showValue: true, showTarget: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BAEAE)),
            child: const Text("Log Value", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {VoidCallback? onClear}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8BAEAE)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 14))),
        if (onClear != null)
          IconButton(
            icon: const Icon(Icons.highlight_off, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClear,
          ),
      ],
    );
  }

  void _showEditDialog(BuildContext outerCtx, String title, {bool showValue = true, bool showTarget = true}) {
    final TextEditingController valueController = TextEditingController();
    final TextEditingController goalController = TextEditingController();
    final String unit = _getUnitForMetric(title);
    bool isLogging = false;
    final bool isWaterIntake = title.toLowerCase() == 'water intake';
    String waterUnit = 'ml';

    showDialog(
      context: outerCtx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDialogState) {
          final String displayUnit = isWaterIntake ? waterUnit : unit;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(showValue && showTarget ? "Log $title" : showValue ? "Log Current $title" : "Set Target for $title"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isWaterIntake) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Unit:', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      ToggleButtons(
                        isSelected: [waterUnit == 'ml', waterUnit == 'L'],
                        onPressed: (i) => setDialogState(() => waterUnit = i == 0 ? 'ml' : 'L'),
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: const Color(0xFF8BAEAE),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
                        children: const [Text('ml'), Text('L')],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (showValue) TextField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Current $title",
                    hintText: isWaterIntake ? (waterUnit == 'L' ? "e.g. 1.5" : "e.g. 1500") : "e.g. 4.5",
                    suffixText: displayUnit,
                  ),
                ),
                if (showValue && showTarget) const SizedBox(height: 10),
                if (showTarget) TextField(
                  controller: goalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Target Goal",
                    hintText: isWaterIntake ? (waterUnit == 'L' ? "e.g. 2.0" : "e.g. 2000") : "e.g. 5.0",
                    suffixText: displayUnit,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text("Cancel")),
              isLogging
                ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      if (valueController.text.isEmpty && goalController.text.isEmpty) return;
                      setDialogState(() => isLogging = true);
                      String backendName = title.toLowerCase().replaceAll(" ", "_");

                      // Convert L → ml before saving so the backend always receives ml
                      String resolvedValue = valueController.text;
                      String resolvedGoal = goalController.text;
                      if (isWaterIntake && waterUnit == 'L') {
                        final v = double.tryParse(valueController.text);
                        if (v != null) resolvedValue = (v * 1000).toStringAsFixed(0);
                        final g = double.tryParse(goalController.text);
                        if (g != null) resolvedGoal = (g * 1000).toStringAsFixed(0);
                      }

                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final customList = prefs.getStringList('custom_metrics_${widget.petId}') ?? [];
                        final isCustom = customList.contains(title);
                        if (isCustom) {
                          final key = title.toLowerCase().replaceAll(" ", "_");
                          if (valueController.text.isNotEmpty) {
                            await prefs.setString('custom_current_${widget.petId}_$key', valueController.text);
                            final histKey = 'custom_history_${widget.petId}_$key';
                            final existing = jsonDecode(prefs.getString(histKey) ?? '[]') as List;
                            final now = DateTime.now();
                            const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                            final timeStr = '${now.day.toString().padLeft(2,'0')} ${mo[now.month-1]} ${now.year}, ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
                            existing.insert(0, {
                              'metric': key,
                              'display': title,
                              'value': valueController.text,
                              'unit': _getUnitForMetric(title),
                              'time': timeStr,
                            });
                            await prefs.setString(histKey, jsonEncode(existing));
                          }
                          if (goalController.text.isNotEmpty) {
                            await prefs.setString('custom_target_${widget.petId}_$key', goalController.text);
                          }
                        } else {
                          if (resolvedValue.isNotEmpty) {
                            await _healthService.logMetric(
                              petId: widget.petId,
                              metricName: backendName,
                              value: resolvedValue,
                            );
                          }
                          if (resolvedGoal.isNotEmpty) {
                            await _healthService.syncGoalToBackend(
                              widget.petId,
                              backendName,
                              resolvedGoal,
                            );
                          }
                        }
                        if (!mounted) return;
                        final effectiveTarget = resolvedGoal.isNotEmpty
                            ? resolvedGoal
                            : (_latestValues[title]?['target'] ?? '');
                        if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                        if (resolvedValue.isNotEmpty) setState(() => _lastLoggedMetric = title);
                        _refreshAllMetrics();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Updated $title successfully!"), backgroundColor: Colors.green.shade700),
                        );
                        if (resolvedValue.isNotEmpty) {
                          await prefs.setString(
                            'last_logged_metric_${widget.petId}',
                            '$title|$resolvedValue|$effectiveTarget',
                          );
                        }
                        if (resolvedValue.isNotEmpty && effectiveTarget.isNotEmpty && mounted) {
                          _checkAndWarnDeviation(context, title, resolvedValue, effectiveTarget);
                        }
                      } catch (e) {
                        setDialogState(() => isLogging = false);
                        debugPrint("Save error: $e");
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving data: $e")));
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
      if (a == _lastLoggedMetric) return -1;
      if (b == _lastLoggedMetric) return 1;
      if (_favorites.contains(a) && !_favorites.contains(b)) return -1;
      if (!_favorites.contains(a) && _favorites.contains(b)) return 1;
      return 0;
    });

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        toolbarHeight: 120,
        centerTitle: true,
        title: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: (widget.petImagePath != null && widget.petImagePath!.isNotEmpty)
                  ? NetworkImage(widget.petImagePath!)
                  : null,
              child: (widget.petImagePath == null || widget.petImagePath!.isEmpty)
                  ? Icon(Icons.add_a_photo, size: 25, color: petThemeColor)
                  : null,
            ),
            const SizedBox(height: 8),
            Text("${widget.petName}'s Metrics", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search Metrics...',
                            fillColor: Colors.white.withValues(alpha: 0.9),
                            filled: true,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            title: const Text("Colour Guide"),
                            content: RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.blueGrey[800], fontSize: 14),
                                children: [
                                  TextSpan(text: "Teal", style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold)),
                                  const TextSpan(text: " = within 15% of target\n\n"),
                                  TextSpan(text: "Orange", style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                                  const TextSpan(text: " = deviates more than 15% from target"),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Got it")),
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(Icons.info_outline, color: Colors.blueGrey[700], size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addCustomMetric,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Custom Metric', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8BAEAE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showDeleteMetricDialog,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Remove Metric', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.85),
                            foregroundColor: Colors.blueGrey[700],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 65.0, right: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox()),
                  Expanded(flex: 1, child: Text("Current", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]))),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: Text("Target", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]))),
                ],
              ),
            ),
            Expanded(
              child: _loadingMetrics
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ListView.builder(
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
    final bool hasTarget = !_noTargetMetrics.contains(title);

    Color statusColor = _getStatusColor(current, hasTarget ? target : '');

    String displayCurrent = (current == "..." || current == "---") ? "" : "$current $unit";
    String displayGoal = target.isNotEmpty ? "$target $unit" : "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white.withValues(alpha: 0.7)),
            onPressed: () => _toggleFavorite(title)
          ),
          Expanded(
            flex: 3,
            child: _metricButton(
              title,
              Colors.white.withValues(alpha: 0.8),
              () => _showInfoDialog(context, title),
              borderColor: statusColor,
              showSpark: true,
            )
          ),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(displayCurrent, const Color.fromARGB(123, 249, 249, 249), () => _showEditDialog(context, title, showValue: true, showTarget: false))),
          const SizedBox(width: 8),
          if (hasTarget)
            Expanded(flex: 1, child: _metricButton(displayGoal, const Color.fromARGB(82, 255, 255, 255), () => _showEditDialog(context, title, showValue: false, showTarget: true)))
          else
            Expanded(flex: 1, child: Container(height: 60)),
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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

  Future<List<String>> getAvailableMetrics(int petId) async {
    final url = Uri.parse("$baseUrl/health/metrics/$petId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<String>((d) => d['name'] as String).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, String>> getLatestMetricData(int petId, String metricName) async {
    final url = Uri.parse("$baseUrl/health/latest?pet_id=$petId&metric_name=$metricName");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "value": data['value']?.toString() ?? "---",
          "target": data['target']?.toString() ?? "",
          "time": data['time']?.toString() ?? data['logged_at']?.toString() ?? "",
          "id": data['id']?.toString() ?? "",
        };
      }
    } catch (_) {}
    return {"value": "---", "target": "", "time": "", "id": ""};
  }

  Future<bool> deleteEntry(int petId, int entryId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/health/history/entry/$petId/$entryId"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAllEntries(int petId, String metricName) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/health/all/$petId/$metricName"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearGoal(int petId, String metricName) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/health/goal/$petId/$metricName"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
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
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maincode/widgets/app_drawer.dart';
import 'package:maincode/utils/image_provider_helper.dart';

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
  Map<String, String> _displayUnits = {}; // Maps metric name -> unit preference (ml/L, mins/hrs)
  Map<String, String> _targetUnits = {}; // Maps metric name -> unit used when target was set

  late String _currentPetName; // Track the current pet name

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
    _currentPetName = widget.petName;
    _loadFavorites();
    _loadMetricsThenRefresh();
  }

  Future<void> _syncPetName() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedName = prefs.getString('pet_name_${widget.petId}');
    if (updatedName != null && updatedName != _currentPetName && mounted) {
      setState(() {
        _currentPetName = updatedName;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync pet name when page comes back from other routes
    // Use a post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPetName();
    });
  }

  Future<void> _loadMetricsThenRefresh() async {
    final fetched = await _healthService.getAvailableMetrics(widget.petId);
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('custom_metrics_${widget.petId}') ?? [];
    final hidden = prefs.getStringList('hidden_metrics_${widget.petId}') ?? [];
    final unitsRaw = prefs.getString('custom_units_${widget.petId}') ?? '{}';
    final unitsMap = Map<String, String>.from(jsonDecode(unitsRaw) as Map);
    final displayUnitsRaw = prefs.getString('display_units_${widget.petId}') ?? '{}';
    final displayUnitsMap = Map<String, String>.from(jsonDecode(displayUnitsRaw) as Map);
    final targetUnitsRaw = prefs.getString('target_units_${widget.petId}') ?? '{}';
    final targetUnitsMap = Map<String, String>.from(jsonDecode(targetUnitsRaw) as Map);
    if (mounted) {
      setState(() {
        _customMetricNames = List<String>.from(custom);
        _metrics = [
          ...custom,
          ...fetched.map(_toDisplayName).where((m) => !hidden.contains(m)),
        ];
        _customUnits = unitsMap;
        _displayUnits = Map<String, String>.from(displayUnitsMap); // Ensure fresh copy of map
        _targetUnits = Map<String, String>.from(targetUnitsMap); // Ensure fresh copy of map
        _loadingMetrics = false;
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

      // Clear last logged metric if it matches the deleted metric
      final lastLogged = prefs.getString('last_logged_metric_${widget.petId}');
      if (lastLogged != null) {
        final lastLoggedTitle = lastLogged.split('|').first;
        if (lastLoggedTitle == name) {
          await prefs.remove('last_logged_metric_${widget.petId}');
        }
      }

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
    const unitOptions = ["kg", "ml", "mins", "hrs", "%", "/5", "count", "none"];
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
    final metricsNotifier = ValueNotifier<List<String>>(List.from(_metrics));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Remove a Metric"),
        content: SizedBox(
          width: double.maxFinite,
          child: ValueListenableBuilder<List<String>>(
            valueListenable: metricsNotifier,
            builder: (_, metrics, _) {
              return metrics.isEmpty
                  ? const Text("No metrics to remove.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: metrics.length,
                      itemBuilder: (_, i) {
                        final name = metrics[i];
                        return ListTile(
                          title: Text(name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmationDialog(
                                name,
                                onConfirm: () async {
                                  await _removeMetric(name);
                                  metricsNotifier.value = List.from(metricsNotifier.value)..remove(name);
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Done")),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String metricName, {required Future<void> Function() onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Deletion"),
        content: Text(
          "Are you sure you want to delete '$metricName'? This metric and all its logged data will be removed from the Metrics page, Recently Logged page, and Reports page. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await onConfirm();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
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
      case "water intake":     return _displayUnits[metricName] == 'L' ? 'L/day' : 'ml/day';
      case "basking time":
      case "wheel activity":   return _displayUnits[metricName] == 'hrs' ? 'hrs/day' : 'mins/day';
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
      default: {
        final customUnit = _customUnits[metricName];
        if (customUnit == null || customUnit == 'none') return '';
        if (customUnit == 'mins') return _displayUnits[metricName] == 'hrs' ? 'hrs/day' : 'mins';
        return customUnit;
      }
    }
  }

  String? _getMetricDescription(String title) {
    switch (title.toLowerCase()) {
      case 'appetite':           return '1 = not eating  ·  5 = eating very well';
      case 'energy level':       return '1 = very lethargic  ·  5 = very energetic';
      case 'stool quality':      return '1 = abnormal / loose  ·  5 = firm and healthy';
      case 'vocalisation level': return '1 = unusually silent  ·  5 = very vocal / chatty';
      case 'perch activity':     return '1 = barely moving  ·  5 = very active on perch';
      case 'wing strength':      return '1 = weak / drooping  ·  5 = strong, held normally';
      case 'feather condition':  return '1 = dull / ruffled / patches missing  ·  5 = glossy and complete';
      case 'shedding quality':   return '1 = excessive or abnormal  ·  5 = normal healthy shed';
      case 'chewing behaviour':  return '1 = not chewing  ·  5 = chewing actively and normally';
      case 'vomit events':       return 'Count of vomiting episodes today — 0 is ideal';
      case 'stool pellets':      return 'Total number of droppings passed today';
      case 'grooming frequency': return 'Number of times you groomed your pet today';
      case 'litter box usage':   return 'Number of litter box visits today';
      default: return null;
    }
  }

  String _targetDisplayUnit(String title) {
    final name = title.toLowerCase();
    final isWater = name == 'water intake';
    final isMins = name == 'basking time' || name == 'wheel activity' || _customUnits[title] == 'mins';
    if (isWater) {
      return _targetUnits[title] == 'L' ? 'L/day' : 'ml/day';
    } else if (isMins) {
      return _targetUnits[title] == 'hrs' ? 'hrs/day' : 'mins/day';
    }
    return _getUnitForMetric(title);
  }

  void _checkAndWarnDeviation(BuildContext ctx, String title, String enteredValue, String targetValue) async {
    final current = double.tryParse(enteredValue);
    final target = double.tryParse(targetValue);
    if (current == null || target == null || target == 0) return;

    final deviation = (current - target).abs() / target;
    if (deviation <= 0.15 || deviation > 5.0) return;

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
            const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text("$title Alert", style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(
          "$title is $percent% ${isAbove ? 'above' : 'below'} the target of ${_toDisplayValue(targetValue, unit)} $unit.\n\nConsider speaking to your vet if this continues.",
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
              neverLogged ? 'Not yet logged' : '${_toDisplayValue(currentVal, unit)} $unit',
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
                targetVal.isEmpty ? 'Not set' : '${_toDisplayValue(targetVal, unit)} $unit',
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
    final bool isMinsMetric = title.toLowerCase() == 'basking time'
        || title.toLowerCase() == 'wheel activity'
        || _customUnits[title] == 'mins';
    final bool isScale = unit == '/5';
    final bool isTargetOnly = !showValue && showTarget;
    final String defaultUnit = isWaterIntake ? 'ml' : 'mins';
    String unitToggle = isTargetOnly
        ? (_targetUnits[title] ?? defaultUnit)
        : (_displayUnits[title] ?? defaultUnit);
    double sliderVal = 3.0;
    double goalSliderVal = 5.0;
    if (isScale) {
      valueController.text = sliderVal.round().toString();
      goalController.text = goalSliderVal.round().toString();
    }

    showDialog(
      context: outerCtx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDialogState) {
          final String displayUnit = (isWaterIntake || isMinsMetric) ? unitToggle : unit;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(showValue && showTarget ? "Log $title" : showValue ? "Log Current $title" : "Set Target for $title"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_getMetricDescription(title) != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BAEAE).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getMetricDescription(title)!,
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey[700]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (isWaterIntake || isMinsMetric) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Unit:', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      ToggleButtons(
                        isSelected: isWaterIntake
                            ? [unitToggle == 'ml', unitToggle == 'L']
                            : [unitToggle == 'mins', unitToggle == 'hrs'],
                        onPressed: (i) => setDialogState(() => unitToggle = isWaterIntake
                            ? (i == 0 ? 'ml' : 'L')
                            : (i == 0 ? 'mins' : 'hrs')),
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: const Color(0xFF8BAEAE),
                        constraints: const BoxConstraints(minWidth: 52, minHeight: 32),
                        children: isWaterIntake
                            ? const [Text('ml'), Text('L')]
                            : const [Text('mins'), Text('hrs')],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (showTarget) ...[
                  if (isScale) ...[
                    Text("Target $title", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('1', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: goalSliderVal,
                            min: 1, max: 5, divisions: 4,
                            activeColor: const Color(0xFF8BAEAE),
                            label: goalSliderVal.round().toString(),
                            onChanged: (v) => setDialogState(() {
                              goalSliderVal = v;
                              goalController.text = v.round().toString();
                            }),
                          ),
                        ),
                        const Text('5', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    Center(
                      child: Text('${goalSliderVal.round()} / 5',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ] else TextField(
                    controller: goalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Target Goal",
                      hintText: isWaterIntake
                          ? (unitToggle == 'L' ? "e.g. 2.0" : "e.g. 2000")
                          : isMinsMetric
                              ? (unitToggle == 'hrs' ? "e.g. 1.5" : "e.g. 90")
                              : "e.g. 5.0",
                      suffixText: displayUnit,
                    ),
                  ),
                ],
                if (showValue && showTarget) const SizedBox(height: 16),
                if (showValue) ...[
                  if (isScale) ...[
                    Text("Current $title", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('1', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: sliderVal,
                            min: 1, max: 5, divisions: 4,
                            activeColor: const Color(0xFF8BAEAE),
                            label: sliderVal.round().toString(),
                            onChanged: (v) => setDialogState(() {
                              sliderVal = v;
                              valueController.text = v.round().toString();
                            }),
                          ),
                        ),
                        const Text('5', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    Center(
                      child: Text('${sliderVal.round()} / 5',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ] else TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Current $title",
                      hintText: isWaterIntake
                          ? (unitToggle == 'L' ? "e.g. 1.5" : "e.g. 1500")
                          : isMinsMetric
                              ? (unitToggle == 'hrs' ? "e.g. 1.5" : "e.g. 90")
                              : "e.g. 4.5",
                      suffixText: displayUnit,
                    ),
                  ),
                ],
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

                      String resolvedValue = valueController.text;
                      String resolvedGoal = goalController.text;
                      if (isWaterIntake && unitToggle == 'L') {
                        final v = double.tryParse(valueController.text);
                        if (v != null) resolvedValue = (v * 1000).toStringAsFixed(0);
                        final g = double.tryParse(goalController.text);
                        if (g != null) resolvedGoal = (g * 1000).toStringAsFixed(0);
                      }
                      if (isMinsMetric && unitToggle == 'hrs') {
                        final v = double.tryParse(valueController.text);
                        if (v != null) resolvedValue = (v * 60).toStringAsFixed(0);
                        final g = double.tryParse(goalController.text);
                        if (g != null) resolvedGoal = (g * 60).toStringAsFixed(0);
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
                        if (isWaterIntake || isMinsMetric) {
                          if (!isTargetOnly) {
                            final updated = Map<String, String>.from(_displayUnits)..[title] = unitToggle;
                            setState(() => _displayUnits = updated);
                            await prefs.setString('display_units_${widget.petId}', jsonEncode(updated));
                          }
                          if (isTargetOnly || resolvedGoal.isNotEmpty) {
                            final updated = Map<String, String>.from(_targetUnits)..[title] = unitToggle;
                            setState(() => _targetUnits = updated);
                            await prefs.setString('target_units_${widget.petId}', jsonEncode(updated));
                          }
                        }
                        if (!mounted) return;
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
                        final valueForDeviation = resolvedValue.isNotEmpty
                            ? resolvedValue
                            : (_latestValues[title]?['value'] ?? '');
                        if (valueForDeviation.isNotEmpty && valueForDeviation != '---' && effectiveTarget.isNotEmpty && mounted) {
                          _checkAndWarnDeviation(context, title, valueForDeviation, effectiveTarget);
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

  void _showCurrentValueOptions(String title) {
    final String currentVal = _latestValues[title]?['value'] ?? '---';
    final bool hasValue = currentVal != '---' && currentVal != '...';

    if (!hasValue) {
      _showEditDialog(context, title, showValue: true, showTarget: false);
      return;
    }

    final String unit = _getUnitForMetric(title);
    final String displayVal = unit == '/5'
        ? '${double.tryParse(currentVal)?.round() ?? currentVal} $unit'
        : '${_toDisplayValue(currentVal, unit)} $unit';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current value: $displayVal', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showEditDialog(context, title, showValue: true, showTarget: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BAEAE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Log New Value', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _doClearCurrentValue(title);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Remove Value', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTargetOptions(String title) {
    final String targetVal = _latestValues[title]?['target'] ?? '';
    final bool hasTarget = targetVal.isNotEmpty;

    if (!hasTarget) {
      _showEditDialog(context, title, showValue: false, showTarget: true);
      return;
    }

    final String unit = _getUnitForMetric(title);
    final String targetUnit = _targetDisplayUnit(title);
    final String displayTarget = unit == '/5'
        ? '${double.tryParse(targetVal)?.round() ?? targetVal} $unit'
        : '${_toDisplayValue(targetVal, targetUnit)} $targetUnit';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('$title Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current target: $displayTarget', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showEditDialog(context, title, showValue: false, showTarget: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BAEAE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Set Target', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _doClearTarget(title);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Remove Target', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doClearCurrentValue(String title) async {
    final String entryId = _latestValues[title]?['id'] ?? '';
    final bool isCustom = _customMetricNames.contains(title);
    final String key = title.toLowerCase().replaceAll(' ', '_');

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

  Future<void> _doClearTarget(String title) async {
    final bool isCustom = _customMetricNames.contains(title);
    final String key = title.toLowerCase().replaceAll(' ', '_');

    bool success = false;
    if (isCustom) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('custom_target_${widget.petId}_$key');
      success = true;
    } else {
      success = await _healthService.clearGoal(widget.petId, key);
    }

    // Clear the target unit when target is cleared
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final updatedTargetUnits = Map<String, String>.from(_targetUnits);
      updatedTargetUnits.remove(title);
      setState(() => _targetUnits = updatedTargetUnits);
      await prefs.setString(
        'target_units_${widget.petId}',
        jsonEncode(updatedTargetUnits),
      );
    }

    if (mounted) {
      _refreshAllMetrics();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Target cleared.' : 'Could not clear target.'),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade400,
      ));
    }
  }

  String _toDisplayValue(String rawValue, String unit) {
    if (rawValue.isEmpty || rawValue == '---' || rawValue == '...') return rawValue;
    if (unit == 'L/day' || unit == 'L') {
      final v = double.tryParse(rawValue);
      if (v != null) {
        final litres = v / 1000;
        return litres % 1 == 0
            ? litres.toInt().toString()
            : litres.toStringAsFixed(litres < 0.1 ? 3 : 2);
      }
    }
    if (unit == 'hrs/day') {
      final v = double.tryParse(rawValue);
      if (v != null) {
        final hours = v / 60;
        return hours % 1 == 0
            ? hours.toInt().toString()
            : hours.toStringAsFixed(hours < 0.1 ? 3 : 2);
      }
    }
    return rawValue;
  }

  Color _getStatusColor(String current, String target) {
    if (current == "---" || target.isEmpty) return Colors.transparent;
    try {
      double c = double.parse(current.replaceAll(RegExp(r'[^0-9\.]'), ''));
      double t = double.parse(target.replaceAll(RegExp(r'[^0-9\.]'), ''));
      if (t == 0) return Colors.transparent;
      double diff = (c - t).abs() / t;

      if (diff > 0.15) return Colors.red;
      return const Color(0xFF4CAF50);
    } catch (_) {
      return Colors.transparent;
    }
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
                  ? (widget.petImagePath!.startsWith('http')
                      ? NetworkImage(HealthService.getImageUrl(widget.petImagePath)) as ImageProvider
                      : buildLocalFileImage(widget.petImagePath!))
                  : null,
              child: (widget.petImagePath == null || widget.petImagePath!.isEmpty)
                  ? Icon(Icons.add_a_photo, size: 25, color: petThemeColor)
                  : null,
            ),
            const SizedBox(height: 8),
            Text("$_currentPetName's Metrics", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8BAEAE), Color(0xFFB2D3C2), Color(0xFFE0F7F4)]),
              ),
            ),
          ),
          Positioned.fill(child: Column(
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
                            prefixIcon: const Icon(Icons.search, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  TextSpan(text: "Green", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                                  const TextSpan(text: " = within 15% of target\n\n"),
                                  TextSpan(text: "Red", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                          label: const Text('Custom Metric', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8BAEAE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showDeleteMetricDialog,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Remove Metric', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.85),
                            foregroundColor: Colors.blueGrey[700],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                      physics: const ClampingScrollPhysics(),
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
        )),
        ],
      ),
    );
  }

  Widget _metricRow(BuildContext context, String title, String current, String target, bool isFavorite) {
    final String unit = _getUnitForMetric(title);
    final bool hasTarget = !_noTargetMetrics.contains(title);

    Color statusColor = _getStatusColor(current, hasTarget ? target : '');

    String displayCurrent;
    if (current == "..." || current == "---") {
      displayCurrent = "";
    } else if (unit == '/5') {
      final d = double.tryParse(current);
      displayCurrent = d != null ? '${d.round()} $unit' : '$current $unit';
    } else {
      displayCurrent = '${_toDisplayValue(current, unit)} $unit';
    }
    String displayGoal;
    if (unit == '/5' && target.isNotEmpty) {
      final d = double.tryParse(target);
      displayGoal = d != null ? '${d.round()} $unit' : '$target $unit';
    } else {
      final String displayGoalUnit = _targetDisplayUnit(title);
      displayGoal = target.isNotEmpty ? '${_toDisplayValue(target, displayGoalUnit)} $displayGoalUnit' : '';
    }

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
              Colors.white,
              null,
              borderColor: statusColor,
            )
          ),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _metricButton(displayCurrent, const Color(0xFFF0F6F5), () => _showCurrentValueOptions(title))),
          const SizedBox(width: 8),
          if (hasTarget)
            Expanded(flex: 1, child: _metricButton(displayGoal, const Color(0xFFE2EFED), () => _showTargetOptions(title)))
          else
            Expanded(flex: 1, child: Container(height: 60)),
        ],
      ),
    );
  }

  Widget _metricButton(String text, Color color, VoidCallback? onTap, {Color borderColor = Colors.transparent}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor != Colors.transparent ? borderColor : Colors.black26,
            width: borderColor != Colors.transparent ? 5.0 : 3.0,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

}


class HealthService {
  static String get baseUrl {
    // Use localhost for web, 10.0.2.2 for Android emulator
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    return "http://10.0.2.2:8000";
  }

  static String getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (!imageUrl.startsWith('http')) return imageUrl;

    // For web, use localhost; for mobile, use 10.0.2.2
    if (kIsWeb) {
      return imageUrl.replaceFirst('http://10.0.2.2', 'http://localhost');
    }
    return imageUrl.replaceFirst('http://localhost', 'http://10.0.2.2');
  }

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

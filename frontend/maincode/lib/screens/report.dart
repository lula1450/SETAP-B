import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Make sure to run 'flutter pub add fl_chart'
import 'package:maincode/services/pet_service.dart';
import 'package:maincode/utils/pdf_helper.dart';
import 'package:maincode/utils/url_helper.dart';
import 'package:maincode/utils/image_provider_helper.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:maincode/screens/route_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsPage extends StatefulWidget {
  final int petId;
  final String petName;
  final int petIndex;
  final String? petImagePath;

  const ReportsPage({super.key, required this.petId, required this.petName, required this.petIndex, this.petImagePath});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with RouteAware {
  final PetService _service = PetService();
  Map<String, dynamic> _analysisData = {};
  bool _isLoading = true;
  String _selectedMetric = "weight";
  List<String> _availableMetrics = [];
  final Set<String> _customMetrics = {};
  final GlobalKey _chartKey = GlobalKey();
  DateTimeRange? _selectedDateRange;
  late String _currentPetName; // Track the current pet name

  @override
  void initState() {
    super.initState();
    _currentPetName = widget.petName;
    _initializePage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPetName();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _initializePage();
  }

  @override
  void didUpdateWidget(ReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when widget updates (e.g., after returning from metrics page)
    if (oldWidget.petId != widget.petId || oldWidget.petName != widget.petName) {
      _initializePage();
    }
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

  // Initialize page: fetch which metrics have logged data, pick a sensible default, then load data
  Future<void> _initializePage() async {
    setState(() => _isLoading = true);
    if (_selectedDateRange == null) {
      final now = DateTime.now();
      _selectedDateRange = DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    }
    try {
      final metrics = await _service.getLoggedMetrics(widget.petId);

      final prefs = await SharedPreferences.getInstance();
      final hidden = prefs.getStringList('hidden_metrics_${widget.petId}') ?? [];
      final hiddenKeys = hidden.map((h) => h.toLowerCase().replaceAll(' ', '_')).toSet();

      final customNames = prefs.getStringList('custom_metrics_${widget.petId}') ?? [];
      final customKeys = <String>[];
      _customMetrics.clear();
      for (final name in customNames) {
        final key = name.toLowerCase().replaceAll(' ', '_');
        final histRaw = prefs.getString('custom_history_${widget.petId}_$key') ?? '[]';
        final entries = jsonDecode(histRaw) as List;
        if (entries.isNotEmpty) {
          customKeys.add(key);
          _customMetrics.add(key);
        }
      }

      if (!mounted) return;
      setState(() {
        _availableMetrics = [...customKeys, ...metrics.where((m) => !hiddenKeys.contains(m))];
        if (!_availableMetrics.contains(_selectedMetric) && _availableMetrics.isNotEmpty) {
          _selectedMetric = _availableMetrics.first;
        }
      });
    } catch (e) {
      debugPrint('Failed to fetch available metrics: $e');
    }
    await _loadData();
  }

  DateTime _parseCustomTime(String t) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    try {
      final parts = t.split(', ');
      final dateParts = parts[0].split(' ');
      final timeParts = parts[1].split(':');
      return DateTime(
        int.parse(dateParts[2]), months[dateParts[1]]!, int.parse(dateParts[0]),
        int.parse(timeParts[0]), int.parse(timeParts[1]),
      );
    } catch (_) {
      return DateTime(2000);
    }
  }

  Future<Map<String, dynamic>> _loadCustomMetricData(String metricKey) async {
    final prefs = await SharedPreferences.getInstance();
    final histRaw = prefs.getString('custom_history_${widget.petId}_$metricKey') ?? '[]';
    var entries = (jsonDecode(histRaw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    entries.sort((a, b) => _parseCustomTime(a['time']?.toString() ?? '')
        .compareTo(_parseCustomTime(b['time']?.toString() ?? '')));

    if (_selectedDateRange != null) {
      final rangeEnd = _selectedDateRange!.end.add(const Duration(days: 1));
      entries = entries.where((e) {
        final t = _parseCustomTime(e['time']?.toString() ?? '');
        return !t.isBefore(_selectedDateRange!.start) && t.isBefore(rangeEnd);
      }).toList();
    }

    final numericEntries = entries
        .where((e) => double.tryParse(e['value'].toString()) != null)
        .toList();

    if (numericEntries.isEmpty) {
      return {"message": "No numeric data to display", "points": [], "is_risk": false};
    }

    final values = numericEntries.map((e) => double.parse(e['value'].toString())).toList();
    final current = values.last;
    final baseline = values.reduce((a, b) => a + b) / values.length;
    final isRisk = baseline != 0 && (current - baseline).abs() / baseline >= 0.15;

    final points = List.generate(numericEntries.length, (i) => {
      "x": i,
      "y": values[i],
      "date": numericEntries[i]['time']?.toString() ?? '',
    });

    return {
      "metric": metricKey,
      "is_risk": isRisk,
      "baseline": baseline,
      "current": current,
      "message": isRisk ? "Significant change detected!" : "Health stable",
      "points": points,
    };
  }

  // Capture the chart widget as PNG bytes
  Future<Uint8List> _capturePng() async {
    RenderRepaintBoundary boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _selectDateRange() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Filter by Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF8BAEAE)),
                title: const Text('Last 7 Days'),
                onTap: () {
                  final now = DateTime.now();
                  Navigator.pop(ctx);
                  setState(() => _selectedDateRange = DateTimeRange(
                    start: now.subtract(const Duration(days: 7)),
                    end: now,
                  ));
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_week, color: Color(0xFF8BAEAE)),
                title: const Text('This Week'),
                onTap: () {
                  final now = DateTime.now();
                  final monday = now.subtract(Duration(days: now.weekday - 1));
                  final start = DateTime(monday.year, monday.month, monday.day);
                  Navigator.pop(ctx);
                  setState(() => _selectedDateRange = DateTimeRange(start: start, end: now));
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Color(0xFF8BAEAE)),
                title: const Text('This Month'),
                onTap: () {
                  final now = DateTime.now();
                  final start = DateTime(now.year, now.month, 1);
                  Navigator.pop(ctx);
                  setState(() => _selectedDateRange = DateTimeRange(start: start, end: now));
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Color(0xFF8BAEAE)),
                title: const Text('Custom Range'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickCustomDateRange();
                },
              ),
              if (_selectedDateRange != null)
                ListTile(
                  leading: const Icon(Icons.clear, color: Colors.red),
                  title: const Text('Clear Filter', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedDateRange = null);
                    _loadData();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final theme = Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8BAEAE),
        onSurface: Colors.black87,
      ),
    );

    final start = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange?.start ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'SELECT START DATE',
      builder: (context, child) => Theme(data: theme, child: child!),
    );
    if (start == null || !mounted) return;

    final end = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange?.end ?? DateTime.now(),
      firstDate: start,
      lastDate: DateTime.now(),
      helpText: 'SELECT END DATE',
      builder: (context, child) => Theme(data: theme, child: child!),
    );
    if (end == null) return;

    setState(() => _selectedDateRange = DateTimeRange(start: start, end: end));
    _loadData();
  }

  String _dateRangeLabel() {
    if (_selectedDateRange == null) return '';
    final now = DateTime.now();
    final start = _selectedDateRange!.start;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final last7 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    if (start.year == last7.year && start.month == last7.month && start.day == last7.day) return 'Last 7 Days';
    if (start == weekStart) return 'This Week';
    if (start == monthStart) return 'This Month';
    return "${start.day}/${start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}";
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final Map<String, dynamic> data;
    if (_customMetrics.contains(_selectedMetric)) {
      data = await _loadCustomMetricData(_selectedMetric);
    } else {
      final String? start = _selectedDateRange?.start.toIso8601String();
      final String? end = _selectedDateRange?.end.toIso8601String();
      data = await _service.getMetricAnalysis(widget.petId, _selectedMetric, startDate: start, endDate: end);
    }
    if (!mounted) return;
    setState(() {
      _analysisData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isRisk = _analysisData['is_risk'] == true;

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BAEAE),
        elevation: 0,
        toolbarHeight: 120,
        centerTitle: true,
        title: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              backgroundImage: (widget.petImagePath != null && widget.petImagePath!.isNotEmpty)
                  ? (widget.petImagePath!.startsWith('http')
                      ? NetworkImage(UrlHelper.getImageUrl(widget.petImagePath)) as ImageProvider
                      : buildLocalFileImage(widget.petImagePath!))
                  : null,
              child: (widget.petImagePath == null || widget.petImagePath!.isEmpty)
                  ? Icon(Icons.add_a_photo, size: 30, color: _getPetColor(widget.petIndex))
                  : null,
            ),
            const SizedBox(height: 8),
            Text('$_currentPetName\'s Report', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
          ],
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
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8BAEAE), Color(0xFFB2D3C2), Color(0xFFE0F7F4)],
          ),
        ),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8BAEAE)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStatusCard(isRisk),
                  const SizedBox(height: 30),
                  if (_selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InputChip(
                        label: Text(_dateRangeLabel()),
                        onDeleted: () {
                          setState(() => _selectedDateRange = null);
                          _loadData();
                        },
                      ),
                    ),
                  Row(
                    children: [
                      const Text("Trend Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            title: const Text("About This Analysis"),
                            content: const Text(
                              'The analysis flags significant changes when the current value deviates by 15% or more from the baseline.',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Got it")),
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(Icons.info_outline, color: Colors.blueGrey[700], size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    key: _chartKey,
                    child: _buildChart(isRisk),
                  ),
                  const SizedBox(height: 30),
                  _buildBaselineInfo(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Export Clinical Report"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        Uint8List chartImage = await _capturePng();
                        await PdfHelper.generateReport(_currentPetName, _selectedMetric, _analysisData, chartImage, dateRange: _selectedDateRange);
                      } catch (e) {
                        debugPrint('PDF preview error: $e');
                        messenger.showSnackBar(const SnackBar(content: Text('Could not generate preview')));
                      }
                    },
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Color _getPetColor(int index) {
    final List<Color> nameColors = [
      const Color.fromARGB(255, 146, 179, 236), // Blue
      const Color.fromRGBO(212, 162, 221, 1), // Purple
      const Color.fromARGB(255, 182, 139, 83), // Brown/Gold
      const Color.fromRGBO(223, 128, 158, 1), // Pink
      const Color.fromARGB(255, 126, 140, 224), // Indigo
      const Color.fromARGB(255, 255, 171, 145), // Coral
      const Color.fromARGB(255, 167, 235, 244), // Cyan
      const Color.fromARGB(255, 219, 247, 240), // Mint
    ];

    if (index < 0) return Colors.grey;
    return nameColors[index % nameColors.length];
  }

  // --- Settings Drawer (using shared AppDrawer) ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Metric:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedMetric,
                  isExpanded: true,
                  items: (_availableMetrics.isNotEmpty
                          ? _availableMetrics
                              .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.replaceAll('_', ' ').toUpperCase()),
                                  ))
                              .toList()
                          : [DropdownMenuItem<String>(
                              value: _selectedMetric,
                              child: Text(_selectedMetric.replaceAll('_', ' ').toUpperCase()),
                            )]),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMetric = val);
                      _loadData();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.date_range),
                tooltip: 'Filter date range',
                onPressed: () async => _selectDateRange(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isRisk) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRisk ? Colors.red[50] : Colors.teal[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isRisk ? Colors.red : Colors.teal, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isRisk ? Icons.warning : Icons.check_circle,
                   color: isRisk ? Colors.red : Colors.teal),
              const SizedBox(width: 10),
              Text(
                isRisk ? "ATTENTION REQUIRED" : "HEALTH STABLE",
                style: TextStyle(fontWeight: FontWeight.bold, color: isRisk ? Colors.red : Colors.teal),
              ),
            ],
          ),
          if (isRisk) ...[
            const SizedBox(height: 10),
            Text((_analysisData['message'] ?? '').replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]|[\u{2600}-\u{27BF}]', unicode: true), '').trim()),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(bool isRisk) {
    final List<dynamic> points = _analysisData['points'] ?? [];
    if (points.isEmpty) return const SizedBox(height: 200, child: Center(child: Text("Not enough data to graph")));

    // Convert backend JSON points to FlSpots
    List<FlSpot> spots = points.map((p) => FlSpot(p['x'].toDouble(), p['y'].toDouble())).toList();

    return Container(
      height: 360,
      padding: const EdgeInsets.only(left: 8, right: 20, top: 20, bottom: 8),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    meta.formattedValue,
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final points = _analysisData['points'] as List<dynamic>? ?? [];
                  final int idx = value.toInt();
                  final int interval = (points.length / 6).ceil().clamp(1, 999);
                  if (points.isNotEmpty && idx % interval == 0 && idx < points.length) {
                    final dateStr = points[idx]['date']?.toString() ?? '';
                    final parts = dateStr.split(',')[0].trim().split(' ');
                    final day = parts.isNotEmpty ? parts[0] : '';
                    final month = parts.length > 1 ? parts[1] : '';
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                        Text(month, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: isRisk ? Colors.red : Colors.teal,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: (isRisk ? Colors.red : Colors.teal).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaselineInfo() {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.show_chart, color: Colors.blueGrey),
        title: const Text("Calculated Baseline"),
        subtitle: const Text("Average based on history"),
        trailing: Text(
          _analysisData['baseline'] != null
              ? (double.tryParse(_analysisData['baseline'].toString())?.toStringAsFixed(2) ?? 'N/A')
              : 'N/A',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
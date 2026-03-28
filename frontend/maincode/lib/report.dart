import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Make sure to run 'flutter pub add fl_chart'
import 'package:maincode/services/pet_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maincode/utils/pdf_helper.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

class ReportsPage extends StatefulWidget {
  final int petId;
  final String petName;

  const ReportsPage({super.key, required this.petId, required this.petName});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final PetService _service = PetService();
  Map<String, dynamic> _analysisData = {};
  bool _isLoading = true;
  String _selectedMetric = "weight"; // Default to weight
  List<String> _availableMetrics = []; // available metrics fetched from backend
  final GlobalKey _chartKey = GlobalKey();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  // Initialize page: fetch which metrics have logged data, pick a sensible default, then load data
  Future<void> _initializePage() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await _service.getLoggedMetrics(widget.petId);
      if (!mounted) return;
      setState(() {
        _availableMetrics = metrics;
        if (!_availableMetrics.contains(_selectedMetric) && _availableMetrics.isNotEmpty) {
          _selectedMetric = _availableMetrics.first;
        }
      });
    } catch (e) {
      debugPrint('Failed to fetch available metrics: $e');
    }
    // Then load the analysis for the selected metric
    await _loadData();
  }

  // Capture the chart widget as PNG bytes
  Future<Uint8List> _capturePng() async {
    RenderRepaintBoundary boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Show native date range picker and refresh data when chosen
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8BAEAE), // Matches app theme
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadData(); // reload with new range
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Standardizing the metric name for the backend
    final String? start = _selectedDateRange?.start.toIso8601String();
    final String? end = _selectedDateRange?.end.toIso8601String();
    final data = await _service.getMetricAnalysis(widget.petId, _selectedMetric, startDate: start, endDate: end);
    if (!mounted) return;
    setState(() {
      _analysisData = data;
      _isLoading = false;
    });
  }

  // Build a dropdown from the dynamically fetched metrics (safe fallback if empty)
  Widget _buildMetricDropdown() {
    if (_availableMetrics.isEmpty) {
      return DropdownButton<String>(
        value: _selectedMetric,
        items: [
          DropdownMenuItem(
            value: _selectedMetric,
            child: Text(_selectedMetric.replaceAll('_', ' ').toUpperCase()),
          ),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedMetric = val);
            _loadData();
          }
        },
      );
    }

    return DropdownButton<String>(
      value: _selectedMetric,
      isExpanded: true,
      items: _availableMetrics.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value.replaceAll('_', ' ').toUpperCase()),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedMetric = val);
          _loadData();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRisk = _analysisData['is_risk'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Health: ${widget.petName}'),
        backgroundColor: const Color(0xFF8BAEAE),
        elevation: 0,
      ),
      body: _isLoading
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
                        label: Text("${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}"),
                        onDeleted: () {
                          setState(() => _selectedDateRange = null);
                          _loadData();
                        },
                      ),
                    ),
                  const Text("Trend Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      try {
                        // Capture the chart image from the RepaintBoundary
                        Uint8List chartImage = await _capturePng();
                        // Generate and preview the PDF with the captured image
                        await PdfHelper.generateReport(widget.petName, _analysisData, chartImage);
                      } catch (e) {
                        debugPrint('PDF preview error: $e');
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not generate preview')));
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

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
          const SizedBox(height: 10),
          Text(_analysisData['message'] ?? 'Gathering data...'),
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
      height: 250,
      padding: const EdgeInsets.only(right: 20, top: 20),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final points = _analysisData['points'] as List<dynamic>? ?? [];
                  final int idx = value.toInt();
                  if (points.isNotEmpty && idx % 5 == 0 && idx < points.length) {
                    final dateStr = points[idx]['date']?.toString() ?? '';
                    return Text(dateStr.split(',')[0], style: const TextStyle(fontSize: 10));
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
               color: isRisk ? Colors.red : Colors.teal,
               barWidth: 5,
               belowBarData: BarAreaData(show: true, color: (isRisk ? Colors.red : Colors.teal).withOpacity(0.1)),
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
          "${_analysisData['baseline'] ?? 'N/A'}",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
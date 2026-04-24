import 'package:flutter/material.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:maincode/widgets/app_drawer.dart';

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  final PetService _service = PetService();
  List<dynamic> _pets = [];
  Map<int, List<dynamic>> _reportsByPet = {}; // pet_id -> list of reports
  int? _selectedPetId;
  bool _isLoading = true;
  String _filterFrequency = "all"; // all, weekly, monthly

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int ownerId = prefs.getInt('owner_id') ?? 0;

      // Fetch all pets
      final pets = await _service.getOwnerPets(ownerId);
      if (!mounted) return;

      setState(() {
        _pets = pets;
        if (_pets.isNotEmpty) {
          _selectedPetId = _pets[0]['pet_id'];
        }
      });

      // Fetch reports for each pet
      if (_selectedPetId != null) {
        await _fetchReportsForPet(_selectedPetId!);
      }
    } catch (e) {
      debugPrint('Error initializing report history: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchReportsForPet(int petId) async {
    try {
      final reports = await _service.getPetReportHistory(petId);
      if (!mounted) return;
      setState(() {
        _reportsByPet[petId] = reports;
      });
    } catch (e) {
      debugPrint('Error fetching reports for pet $petId: $e');
    }
  }

  List<dynamic> _getFilteredReports() {
    if (_selectedPetId == null) return [];
    final reports = _reportsByPet[_selectedPetId] ?? [];

    if (_filterFrequency == "all") {
      return reports;
    } else {
      return reports
          .where((report) => report['report_frequency'] == _filterFrequency)
          .toList();
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day} ${_getMonthName(date.month)} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  Map<String, dynamic> _parseSummary(String summaryJson) {
    try {
      return json.decode(summaryJson);
    } catch (e) {
      debugPrint('Error parsing summary: $e');
      return {};
    }
  }

  Widget _buildReportCard(dynamic report) {
    final summary = _parseSummary(report['report_summary']);
    final riskFlags = summary['risk_flags'] ?? [];
    final metrics = summary['metrics'] ?? {};

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            // Report type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: report['report_frequency'] == 'weekly'
                    ? const Color(0xFF8BAEAE)
                    : const Color.fromARGB(255, 212, 162, 221),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report['report_frequency'] == 'weekly'
                    ? 'Weekly Report'
                    : 'Monthly Report',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Risk status indicator
            report['has_risk_flags']
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Risk Flags',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Stable',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_formatDate(report['report_date']),
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
                "Period: ${_formatDate(report['start_date'])} to ${_formatDate(report['end_date'])}",
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Summary
                const Text(
                  'Metrics Summary',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...metrics.entries.map((entry) {
                  final metricName = entry.key;
                  final metricData = entry.value;
                  final status = metricData['status'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metricName
                                    .replaceAll('_', ' ')
                                    .split(' ')
                                    .map((w) =>
                                        w[0].toUpperCase() + w.substring(1))
                                    .join(' '),
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                'Latest: ${metricData['latest']?.toStringAsFixed(2) ?? 'N/A'} | Avg: ${(metricData['average'] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'at_risk'
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status == 'at_risk' ? '⚠️ At Risk' : '✅ Stable',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == 'at_risk'
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                // Risk Flags if any
                if (riskFlags.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Risk Flags Detected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...riskFlags.map((flag) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flag['metric']
                                      .replaceAll('_', ' ')
                                      .split(' ')
                                      .map((w) =>
                                          w[0].toUpperCase() + w.substring(1))
                                      .join(' '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  'Current: ${(flag['current'] ?? 0).toStringAsFixed(2)} | Baseline: ${(flag['baseline'] ?? 0).toStringAsFixed(2)} | Deviation: ${(flag['deviation_percent'] ?? 0).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 174, 174),
        elevation: 0,
        title: const Text(
          'Report History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8BAEAE),
              Color(0xFFB2D3C2),
              Color(0xFFE0F7F4),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet Selector
                    if (_pets.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Pet',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _pets.map((pet) {
                                final isSelected = _selectedPetId == pet['pet_id'];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedPetId = pet['pet_id']);
                                    _fetchReportsForPet(pet['pet_id']);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF8BAEAE)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      pet['pet_first_name'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? const Color(0xFF8BAEAE)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    // Information Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Color(0xFF8BAEAE)),
                              SizedBox(width: 8),
                              Text(
                                'Report Generation Schedule',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8BAEAE),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '📅 Weekly Reports: Generated every Wednesday at 10:30 AM\n'
                            '📊 Monthly Reports: Generated on the 2nd of each month at 10:30 AM',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reports analyze the previous 7 or 30 days of health metrics data.',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filter Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _filterFrequency = "all"),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _filterFrequency == "all"
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'All Reports',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _filterFrequency == "all"
                                      ? const Color(0xFF8BAEAE)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _filterFrequency = "weekly"),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _filterFrequency == "weekly"
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Weekly',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _filterFrequency == "weekly"
                                      ? const Color(0xFF8BAEAE)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _filterFrequency = "monthly"),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _filterFrequency == "monthly"
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Monthly',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _filterFrequency == "monthly"
                                      ? const Color(0xFF8BAEAE)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Reports List
                    if (filteredReports.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 48,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No reports available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: filteredReports
                            .map((report) => _buildReportCard(report))
                            .toList(),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

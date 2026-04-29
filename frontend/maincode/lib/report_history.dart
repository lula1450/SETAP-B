import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart' as open_file;

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  final PetService _service = PetService();
  List<dynamic> _pets = [];
  Map<int, List<dynamic>> _reportsByPet = {};
  int? _selectedPetId;
  bool _isLoading = true;
  String _filterFrequency = "all"; // all, weekly, monthly, custom
  List<Map<String, dynamic>> _customReports = [];

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

      final pets = await _service.getOwnerPets(ownerId);
      if (!mounted) return;

      setState(() {
        _pets = pets;
        if (_pets.isNotEmpty) {
          _selectedPetId = _pets[0]['pet_id'];
        }
      });

      if (_selectedPetId != null) {
        await _fetchReportsForPet(_selectedPetId!);
        await _loadCustomReports(_selectedPetId!);
      }
    } catch (e) {
      debugPrint('Error initializing report history: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadCustomReports(int petId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('custom_reports_$petId') ?? '[]';
    try {
      final list = (jsonDecode(raw) as List)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => _customReports = list);
    } catch (_) {
      if (mounted) setState(() => _customReports = []);
    }
  }

  Future<void> _uploadCustomReport() async {
    if (_selectedPetId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;

    // On web, we store the bytes; on native platforms, we store the path
    String storagePath = '';
    
    if (kIsWeb) {
      // On web, use bytes - store a base64 encoded version
      if (picked.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file bytes.')),
          );
        }
        return;
      }
      // Create a simple identifier for web files
      storagePath = 'web_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    } else {
      // On native platforms, use the file path
      if (picked.path == null) return;
      
      // Copy file into app documents so it persists
      final docsDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(docsDir.path, 'custom_reports'));
      await destDir.create(recursive: true);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      storagePath = p.join(destDir.path, fileName);
      await File(picked.path!).copy(storagePath);
    }

    final entry = {
      'name': picked.name,
      'path': storagePath,
      'date': DateTime.now().toIso8601String(),
      if (kIsWeb) 'bytes': picked.bytes != null ? _bytesToBase64(picked.bytes!) : null,
    };

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('custom_reports_${_selectedPetId!}') ?? '[]';
    final list = (jsonDecode(raw) as List)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.insert(0, entry);
    await prefs.setString('custom_reports_${_selectedPetId!}', jsonEncode(list));

    if (mounted) setState(() => _customReports = list);
  }

  String _bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }

  Future<void> _deleteCustomReport(int index) async {
    if (_selectedPetId == null) return;
    final removed = _customReports[index];

    setState(() => _customReports.removeAt(index));

    // Delete the file from disk
    try {
      final f = File(removed['path'] as String);
      if (await f.exists()) await f.delete();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'custom_reports_${_selectedPetId!}', jsonEncode(_customReports));
  }

  Future<void> _openCustomReport(Map<String, dynamic> report) async {
    if (kIsWeb) {
      // On web, we can't directly open files, so show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File viewing is not available on web version. File data is stored locally.'),
          ),
        );
      }
    } else {
      // On native platforms, use OpenFilex
      try {
        final path = report['path'] as String;
        if (await File(path).exists()) {
          await _openFile(path);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File not found.')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error opening file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: $e')),
          );
        }
      }
    }
  }

  Future<void> _openFile(String path) async {
    try {
      // On native platforms, use open_filex to open the file with system default app
      await open_file.OpenFilex.open(path);
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
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
                  fontSize: 14,
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
                        Icon(Icons.warning_amber, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Risk Flags',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
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
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Stable',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
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
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text(
                "Period: ${_formatDate(report['start_date'])} to ${_formatDate(report['end_date'])}",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Latest: ${metricData['latest']?.toStringAsFixed(2) ?? 'N/A'} | Avg: ${(metricData['average'] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
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
                              fontSize: 13,
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
                          fontSize: 15,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  'Current: ${(flag['current'] ?? 0).toStringAsFixed(2)} | Baseline: ${(flag['baseline'] ?? 0).toStringAsFixed(2)} | Deviation: ${(flag['deviation_percent'] ?? 0).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
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
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
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
            ),
          ),
          Positioned(
            top: -40,
            left: -100,
            child: _backgroundCircle(350, Colors.white.withValues(alpha: 0.1)),
          ),
          Positioned(
            top: -20,
            left: -70,
            child: _backgroundCircle(370, Colors.white.withValues(alpha: 0.2)),
          ),
          Positioned(
            top: 10,
            left: -30,
            child: _backgroundCircle(340, Colors.white.withValues(alpha: 0.3)),
          ),
          Positioned(
            bottom: -40,
            right: -100,
            child: _backgroundCircle(350, Colors.white.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: -20,
            right: -70,
            child: _backgroundCircle(370, Colors.white.withValues(alpha: 0.2)),
          ),
          Positioned(
            bottom: 10,
            right: -30,
            child: _backgroundCircle(340, Colors.white.withValues(alpha: 0.3)),
          ),
          Positioned.fill(
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
                              color: Colors.black,
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
                                    _loadCustomReports(pet['pet_id'] as int);
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
                                          : Colors.white.withValues(alpha: 0.75),
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
                                  fontSize: 14,
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
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reports analyze the previous 7 or 30 days of health metrics data.',
                            style: TextStyle(
                              fontSize: 11,
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
                                    : Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'All Reports',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
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
                                    : Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Weekly',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
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
                                    : Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Monthly',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _filterFrequency == "monthly"
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
                                setState(() => _filterFrequency = "custom"),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _filterFrequency == "custom"
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Custom',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _filterFrequency == "custom"
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
                    if (_filterFrequency == "custom") ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Custom Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8BAEAE),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _uploadCustomReport,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_customReports.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(Icons.upload_file, size: 48,
                                    color: Colors.white.withValues(alpha: 0.75)),
                                const SizedBox(height: 8),
                                Text(
                                  'No custom reports uploaded yet',
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
                          children: List.generate(
                            _customReports.length,
                            (i) => _buildCustomReportCard(_customReports[i], i),
                          ),
                        ),
                    ] else if (filteredReports.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.75),
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
        ],
      ),
    );
  }

  Widget _buildCustomReportCard(Map<String, dynamic> report, int index) {
    final dateStr = report['date'] as String? ?? '';
    String formattedDate = dateStr;
    try {
      final dt = DateTime.parse(dateStr);
      formattedDate = "${dt.day} ${_getMonthName(dt.month)} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {}

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8BAEAE).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.insert_drive_file, color: Color(0xFF8BAEAE), size: 28),
        ),
        title: Text(
          report['name'] as String? ?? 'Custom Report',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Uploaded: $formattedDate',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Color(0xFF8BAEAE)),
              tooltip: 'Open',
              onPressed: () => _openCustomReport(report),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () => _deleteCustomReport(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 30),
      ),
    );
  }
}
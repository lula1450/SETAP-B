import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:maincode/widgets/app_drawer.dart';

class RecentlyLoggedDataPage extends StatefulWidget {
  final int petId;
  final String petName;
  final String? petImagePath;

  const RecentlyLoggedDataPage({
    super.key,
    required this.petId,
    required this.petName,
    this.petImagePath,
  });

  @override
  State<RecentlyLoggedDataPage> createState() => _RecentlyLoggedDataPageState();
}

class _RecentlyLoggedDataPageState extends State<RecentlyLoggedDataPage> {
  final PetService _service = PetService();
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final List<Map<String, dynamic>> _loadedLogs = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredLogs {
    if (_searchQuery.isEmpty) return _loadedLogs;
    final q = _searchQuery.toLowerCase();
    return _loadedLogs.where((log) {
      final isCustom = log['isCustom'] == true;
      final displayName = isCustom
          ? (log['display'] as String? ?? (log['metric'] as String).replaceAll('_', ' '))
          : (log['metric'] as String).replaceAll('_', ' ');
      final time = log['time']?.toString() ?? '';
      return displayName.toLowerCase().contains(q) || time.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadAllHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _loadedLogs.clear();
      _historyFuture = _loadAllHistory();
    });
  }

  Future<List<Map<String, dynamic>>> _loadAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> all = [];

    // Backend history — fail-safe so custom entries still show if backend is down
    try {
      final backendRaw = await _service.getPetHistory(widget.petId);
      all.addAll(
        backendRaw.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {}

    // Custom metric history from SharedPreferences
    final customNames = prefs.getStringList('custom_metrics_${widget.petId}') ?? [];
    for (final name in customNames) {
      final key = name.toLowerCase().replaceAll(' ', '_');
      final histRaw = prefs.getString('custom_history_${widget.petId}_$key') ?? '[]';
      try {
        final entries = jsonDecode(histRaw) as List;
        for (final e in entries) {
          all.add({
            'metric': key,
            'display': e['display'] ?? name,
            'value': e['value'],
            'unit': e['unit'] ?? '',
            'time': e['time'],
            'isCustom': true,
          });
        }
      } catch (_) {}
    }

    all.sort((a, b) => _parseTime(b['time']?.toString() ?? '').compareTo(
                        _parseTime(a['time']?.toString() ?? '')));
    return all;
  }

  DateTime _parseTime(String t) {
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

  Future<void> _deleteLog(Map<String, dynamic> log, int index) async {
    setState(() => _loadedLogs.removeAt(index));

    final isCustom = log['isCustom'] == true;
    bool success;
    if (isCustom) {
      success = await _deleteCustomLog(log);
    } else if (log['id'] != null) {
      success = await _service.deleteHealthLog(widget.petId, log['id'] as int);
    } else {
      success = await _deleteLocalStandardLog(log);
    }

    if (!success && mounted) {
      setState(() => _loadedLogs.insert(index, log));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete log entry.')),
      );
    }
  }

  Future<bool> _deleteLocalStandardLog(Map<String, dynamic> log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'standard_history_${widget.petId}';
      final existing = List<Map<String, dynamic>>.from(
        (jsonDecode(prefs.getString(key) ?? '[]') as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final before = existing.length;
      existing.removeWhere((e) =>
          e['metric'] == log['metric'] &&
          e['time'] == log['time'] &&
          e['value'].toString() == log['value'].toString());
      if (existing.length < before) {
        await prefs.setString(key, jsonEncode(existing));
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteCustomLog(Map<String, dynamic> log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metric = log['metric'] as String;
      final key = 'custom_history_${widget.petId}_$metric';
      final histRaw = prefs.getString(key) ?? '[]';
      
      debugPrint('Attempting to delete: metric=$metric, key=$key');
      debugPrint('Current storage: $histRaw');
      
      final entries = List<Map<String, dynamic>>.from(
        (jsonDecode(histRaw) as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      
      final initialLength = entries.length;
      debugPrint('Entries before delete: $initialLength');
      
      entries.removeWhere((e) {
        final matches = e['time'] == log['time'] && 
               e['value'].toString() == log['value'].toString() &&
               e['metric'] == metric;
        if (matches) {
          debugPrint('Found match: $e');
        }
        return matches;
      });
      
      debugPrint('Entries after delete: ${entries.length}');
      
      if (entries.length < initialLength) {
        await prefs.setString(key, jsonEncode(entries));
        debugPrint('Successfully deleted and saved');
        return true;
      } else {
        debugPrint('No entries were deleted');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting custom log: $e');
      return false;
    }
  }

  void _showLogDetails(BuildContext context, Map<String, dynamic> log, int index, String displayName, bool isCustom) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Value: ${log['value']} ${_formatUnit(log['unit']?.toString())}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text('Logged: ${log['time']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _deleteLog(log, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BAEAE),
        toolbarHeight: 120,
        centerTitle: true,
        title: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: (widget.petImagePath != null && widget.petImagePath!.isNotEmpty)
                  ? (widget.petImagePath!.startsWith('http')
                      ? NetworkImage(widget.petImagePath!.replaceFirst('http://localhost', 'http://10.0.2.2')) as ImageProvider
                      : FileImage(File(widget.petImagePath!)))
                  : null,
              child: (widget.petImagePath == null || widget.petImagePath!.isEmpty)
                  ? const Icon(Icons.add_a_photo, size: 25, color: Color(0xFF8BAEAE))
                  : null,
            ),
            const SizedBox(height: 8),
            Text("${widget.petName}'s Logged Data", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (_loadedLogs.isEmpty && snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            _loadedLogs.addAll(snapshot.data!);
          }
          if (_loadedLogs.isEmpty) {
            return const Center(child: Text('No data logged yet.'));
          }

          final filtered = _filteredLogs;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8BAEAE), Color(0xFFB2D3C2), Color(0xFFE0F7F4)],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by metric or date…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const Expanded(child: Center(child: Text('No matching entries.')))
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => _refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final log = filtered[index];
                          final actualIndex = _loadedLogs.indexOf(log);
                          final isCustom = log['isCustom'] == true;
                          final displayName = isCustom
                              ? (log['display'] as String? ?? (log['metric'] as String).replaceAll('_', ' '))
                              : (log['metric'] as String).replaceAll('_', ' ').toUpperCase();
                          return Card(
                            key: ValueKey('${log['metric']}_${log['time']}_$index'),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              onTap: () => _showLogDetails(context, log, actualIndex, displayName, isCustom),
                              leading: CircleAvatar(
                                backgroundColor: isCustom
                                    ? Colors.purple.withValues(alpha: 0.15)
                                    : const Color(0xFF8BAEAE).withValues(alpha: 0.2),
                                child: isCustom
                                    ? const Icon(Icons.edit_note, color: Colors.purple)
                                    : _getIcon(log['metric'] as String),
                              ),
                              title: Text(
                                displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(log['time']?.toString() ?? ''),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${log['value']}",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _formatUnit(log['unit']?.toString()),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatUnit(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    switch (raw.toLowerCase()) {
      case 'scale_1_5': return '/5';
      case 'ml_per_day': return 'ml/day';
      case 'kg': return 'kg';
      default: return raw;
    }
  }

  Widget _getIcon(String metric) {
    switch (metric.toLowerCase()) {
      case 'weight': return const Icon(Icons.fitness_center, color: Color(0xFF8BAEAE));
      case 'water_intake': return const Icon(Icons.water_drop, color: Colors.blue);
      case 'appetite': return const Icon(Icons.restaurant, color: Colors.orange);
      default: return const Icon(Icons.analytics, color: Colors.grey);
    }
  }
}
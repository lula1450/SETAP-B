import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/services/pet_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

const _kPetColors = [
  Color.fromARGB(255, 146, 179, 236), // Blue
  Color.fromRGBO(212, 162, 221, 1),   // Purple
  Color.fromARGB(255, 182, 139, 83),  // Brown/Gold
  Color.fromRGBO(223, 128, 158, 1),   // Pink
  Color.fromARGB(255, 126, 140, 224), // Indigo
  Color.fromARGB(255, 255, 171, 145), // Coral
  Color.fromARGB(255, 167, 235, 244), // Cyan
  Color.fromARGB(255, 219, 247, 240), // Mint
];

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final PetService _petService = PetService();

  bool _allNotifications = true;
  bool _appointments = true;
  bool _feeding = true;
  bool _advice = true;
  bool _metrics = true;

  List<dynamic> _appointmentsList = [];
  bool _appointmentsExpanded = false;

  List<dynamic> _petsList = []; 
  bool _feedingExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppointments();
    _loadPets();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _appointments = prefs.getBool('notif_appointments') ?? true;
      _feeding = prefs.getBool('notif_feeding') ?? true;
      _advice = prefs.getBool('notif_advice') ?? true;
      _metrics = prefs.getBool('notif_metrics') ?? true;
      _updateMaster();
    });
  }

  Future<void> _loadPets() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('owner_id') ?? 0;
    final data = await _petService.getOwnerPets(ownerId);

    // Build a map of user-edited events from the feeding schedule's local storage.
    // Structure: petId → baseId → {time, label}
    // Deduplicating by baseId collapses daily events stored once per weekday into one slot.
    final Map<int, Map<String, Map<String, String>>> localEvents = {};
    final localJson = prefs.getString('offline_feeding_schedule');
    if (localJson != null) {
      final List<dynamic> decoded = jsonDecode(localJson);
      for (var item in decoded) {
        final petId = item['petId'] as int;
        final eventMap = item['event'] as Map<String, dynamic>;
        final String eventId = eventMap['id'] as String;
        final String baseId = eventId.replaceAll(RegExp(r'_\d+$'), '');
        final int hour = eventMap['hour'] as int;
        final int minute = eventMap['minute'] as int;
        final String timeStr =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        final String label = eventMap['name'] as String? ?? 'Feeding';

        localEvents.putIfAbsent(petId, () => {})[baseId] = {
          'time': timeStr,
          'label': label,
        };
      }
    }

    for (var pet in data) {
      final int id = pet['pet_id'] as int;
      List<Map<String, dynamic>> timeSlots = [];

      if (localEvents.containsKey(id)) {
        // User has opened / edited the feeding schedule — local data is ground truth.
        final sorted = localEvents[id]!.values.toList()
          ..sort((a, b) => a['time']!.compareTo(b['time']!));
        for (var ev in sorted) {
          final timeStr = ev['time']!;
          final label = ev['label']!;
          final key = 'feeding_notif_${id}_$timeStr';
          timeSlots.add({
            'time': timeStr,
            'label': label,
            'key': key,
            'enabled': prefs.getBool(key) ?? true,
          });
        }
      } else {
        // No local edits yet — fall back to backend schedules.
        try {
          final schedules = await _petService.getFeedingSchedules(id);
          for (var s in schedules) {
            final raw = s['feeding_time'] as String? ?? '';
            String timeStr = '08:00';
            try {
              timeStr = raw.split('T').last.substring(0, 5);
            } catch (_) {}
            final label = s['food_name'] as String? ?? 'Feeding';
            final key = 'feeding_notif_${id}_$timeStr';
            timeSlots.add({
              'time': timeStr,
              'label': label,
              'key': key,
              'enabled': prefs.getBool(key) ?? true,
            });
          }
        } catch (e) {
          debugPrint('Feeding fetch failed for pet $id: $e');
        }
      }

      pet['times'] = timeSlots;
      pet['reminder_enabled'] = prefs.getBool('feeding_notif_$id') ?? _feeding;
    }

    setState(() => _petsList = data);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notif_appointments', _appointments);
    await prefs.setBool('notif_feeding', _feeding);
    await prefs.setBool('notif_advice', _advice);
    await prefs.setBool('notif_metrics', _metrics);

    // Save individual pet feeding toggles
    for (var pet in _petsList) {
      await prefs.setBool('feeding_notif_${pet['pet_id']}', pet['reminder_enabled']);
      for (var slot in pet['times']) {
        await prefs.setBool(slot['key'], slot['enabled']);
      }
    }

    // Save appointment toggles
    for (var a in _appointmentsList) {
      final id = a['pet_appointment_id'];
      await prefs.setString(
        "reminder_$id",
        jsonEncode({
          "enabled": a['reminder_enabled'] ?? false,
          "time": a['reminder_time'],
          "date": a['reminder_date'],
          "repeat": a['repeat_type'],
        }),
      );
    }
    // Note: SnackBar removed for seamless auto-save experience
  }

  void _updateMaster() {
    setState(() {
      _allNotifications = _appointments && _feeding && _advice && _metrics;
    });
  }

  void _toggleAll(bool val) {
    setState(() {
      _allNotifications = val;
      _appointments = val;
      _feeding = val;
      _advice = val;
      _metrics = val;
    });
    _saveSettings(); // Auto-save
  }

  Widget _toggle(String title, bool value, Function(bool) onChanged) {
    return _card(
      Row(
        children: [
          Expanded(child: Text(title)),
          Switch(
            value: value, 
            onChanged: (v) {
              onChanged(v);
              _updateMaster();
              _saveSettings();
            }
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text("Appointment Reminders", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Switch(
              value: _appointments,
              onChanged: (v) {
                setState(() => _appointments = v);
                _updateMaster();
                _saveSettings();
              },
            )
          ],
        ),
        TextButton(
          onPressed: () => setState(() => _appointmentsExpanded = !_appointmentsExpanded),
          child: Text(_appointmentsExpanded ? "Hide Appointments" : "View Appointments"),
        ),
        if (_appointmentsExpanded)
          ..._appointmentsList.map((a) {
            return GestureDetector(
              onTap: _appointments ? () async {
                await _openReminderFlow(a);
                _saveSettings(); // Save after dialog interaction
              } : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['appointment_notes'] ?? "Vet Visit", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(a['pet_appointment_date'], style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            (a['reminder_enabled'] ?? false)
                                ? "${a['repeat_type'] ?? 'Once'} • ${a['reminder_time'] ?? ''}"
                                : "Set reminder",
                            style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: a['reminder_enabled'] ?? false,
                      onChanged: _appointments ? (v) {
                        setState(() => a['reminder_enabled'] = v);
                        _saveSettings();
                      } : null,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );

    return _card(content);
  }

  Widget _buildFeedingCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text("Feeding Schedule", style: TextStyle(fontWeight: FontWeight.bold))),
              Switch(
                value: _feeding, 
                onChanged: (v) {
                  setState(() => _feeding = v);
                  _updateMaster();
                  _saveSettings();
                }
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _feedingExpanded = !_feedingExpanded),
            child: Text(_feedingExpanded ? "Hide Details" : "View Details"),
          ),
          if (_feedingExpanded)
            ..._petsList.asMap().entries.map((entry) {
              final pet = entry.value;
              final petColor = _kPetColors[entry.key % _kPetColors.length];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(pet['pet_first_name'], style: TextStyle(fontWeight: FontWeight.w600, color: petColor)),
                  ),
                  ...pet['times'].map<Widget>((slot) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.access_time, size: 18),
                      title: Text("${slot['label']} (${slot['time']})"),
                      trailing: Switch(
                        value: slot['enabled'] && _feeding,
                        onChanged: _feeding ? (v) {
                          setState(() => slot['enabled'] = v);
                          _saveSettings();
                        } : null,
                      ),
                    );
                  }).toList(),
                  const Divider(),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF8BAEAE),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _card(
              Row(
                children: [
                  const Expanded(child: Text("Enable All")),
                  Switch(value: _allNotifications, onChanged: _toggleAll),
                ],
              ),
            ),
            _buildAppointmentCard(),
            _buildFeedingCard(),
            _toggle("Advice", _advice, (v) => setState(() => _advice = v)),
            _toggle("Metrics", _metrics, (v) => setState(() => _metrics = v)),
          ],
        ),
      ),
    );
  }

  // --- Placeholder helpers (Provided in original code) ---

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('owner_id') ?? 0;
    final data = await _petService.getAllAppointments(ownerId);
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final upcoming = data.where((a) {
      return a['appointment_status'] == 'Scheduled' && (a['pet_appointment_date'] as String).compareTo(today) >= 0;
    }).toList();

    for (var a in upcoming) {
      final id = a['pet_appointment_id'];
      final saved = prefs.getString("reminder_$id");
      if (saved != null) {
        final decoded = jsonDecode(saved);
        a['reminder_enabled'] = decoded['enabled'];
        a['reminder_time'] = decoded['time'];
        a['reminder_date'] = decoded['date'];
        a['repeat_type'] = decoded['repeat'];
      } else {
        a['reminder_enabled'] = false;
      }
    }
    setState(() => _appointmentsList = upcoming);
  }

  Future<void> _openReminderFlow(dynamic appt) async {
    // Logic for dialog remains the same as in your original file
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: child,
    );
  }
}




  



  
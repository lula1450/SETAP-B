import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:maincode/services/notification_service.dart';

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
  final _notif = NotificationService();

  bool _allNotifications = true;
  bool _appointments = true;
  bool _feeding = true;
  bool _advice = true;
  bool _metrics = true;

  int _adviceHour = 9;
  int _adviceMinute = 0;

  List<dynamic> _appointmentsList = [];
  bool _appointmentsExpanded = false;

  List<dynamic> _petsList = [];
  bool _feedingExpanded = false;
  bool _metricsExpanded = false;
  bool _adviceExpanded = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _loadSettings();
    await Future.wait([_loadAppointments(), _loadPets()]);
    _rescheduleAll();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appointments = prefs.getBool('notif_appointments') ?? true;
      _feeding = prefs.getBool('notif_feeding') ?? true;
      _advice = prefs.getBool('notif_advice') ?? true;
      _metrics = prefs.getBool('notif_metrics') ?? true;
      _adviceHour = prefs.getInt('advice_hour') ?? 9;
      _adviceMinute = prefs.getInt('advice_minute') ?? 0;
      _updateMaster();
    });
  }

  Future<void> _loadPets() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('owner_id') ?? 0;
    final data = await _petService.getOwnerPets(ownerId);

    final Map<int, Map<String, Map<String, dynamic>>> localEvents = {};
    final localJson = prefs.getString('offline_feeding_schedule');
    if (localJson != null) {
      final List<dynamic> decoded = jsonDecode(localJson);
      for (var item in decoded) {
        final petId = item['petId'] as int;
        final eventMap = item['event'] as Map<String, dynamic>;
        final String eventId = eventMap['id'] as String;
        final String baseId = eventId.replaceAll(RegExp(r'_[0-6]$'), '');
        final int hour = eventMap['hour'] as int;
        final int minute = eventMap['minute'] as int;
        final String timeStr =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        final String label = eventMap['name'] as String? ?? 'Feeding';
        final bool repeatDaily = eventMap['repeatDaily'] as bool? ?? true;
        localEvents.putIfAbsent(petId, () => {})[baseId] = {
          'time': timeStr,
          'label': label,
          'repeatDaily': repeatDaily,
        };
      }
    }

    for (var pet in data) {
      final int id = pet['pet_id'] as int;
      List<Map<String, dynamic>> timeSlots = [];

      if (localEvents.containsKey(id)) {
        final sortedEntries = localEvents[id]!.entries.toList()
          ..sort((a, b) => (a.value['time'] as String).compareTo(b.value['time'] as String));
        for (var entry in sortedEntries) {
          final baseId = entry.key;
          final ev = entry.value;
          final timeStr = ev['time'] as String;
          final label = ev['label'] as String;
          final repeatDaily = ev['repeatDaily'] as bool? ?? true;
          final key = 'feeding_notif_${id}_$timeStr';
          timeSlots.add({
            'time': timeStr,
            'label': label,
            'key': key,
            'enabled': prefs.getBool(key) ?? true,
            'baseId': baseId,
            'repeatDaily': repeatDaily,
          });
        }
      } else {
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
              'baseId': 'backend_${s['feeding_schedule_id']}',
              'repeatDaily': true,
            });
          }
        } catch (e) {
          debugPrint('Feeding fetch failed for pet $id: $e');
        }
      }

      pet['times'] = timeSlots;
      pet['reminder_enabled'] = prefs.getBool('feeding_notif_$id') ?? _feeding;

      final hidden = prefs.getStringList('hidden_metrics_$id') ?? [];
      final custom = prefs.getStringList('custom_metrics_$id') ?? [];
      List<String> allMetrics = [];
      try {
        allMetrics = await _petService.getAvailableMetrics(id);
      } catch (_) {}
      for (final c in custom) {
        if (!allMetrics.contains(c)) allMetrics.add(c);
      }
      allMetrics.removeWhere((m) => hidden.contains(m));

      pet['metrics'] = allMetrics.map((name) {
        final key = 'metrics_notif_${id}_${name.toLowerCase().replaceAll(' ', '_')}';
        return {
          'name': name,
          'key': key,
          'enabled': prefs.getBool(key) ?? true,
        };
      }).toList();
      pet['metrics_enabled'] = prefs.getBool('metrics_notif_$id') ?? _metrics;
      pet['advice_enabled'] = prefs.getBool('advice_notif_$id') ?? _advice;
    }

    setState(() => _petsList = data);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_appointments', _appointments);
    await prefs.setBool('notif_feeding', _feeding);
    await prefs.setBool('notif_advice', _advice);
    await prefs.setBool('notif_metrics', _metrics);
    await prefs.setInt('advice_hour', _adviceHour);
    await prefs.setInt('advice_minute', _adviceMinute);

    for (var pet in _petsList) {
      final id = pet['pet_id'];
      await prefs.setBool('feeding_notif_$id', pet['reminder_enabled']);
      for (var slot in (pet['times'] as List)) {
        await prefs.setBool(slot['key'], slot['enabled']);
      }
      await prefs.setBool('metrics_notif_$id', pet['metrics_enabled'] ?? true);
      for (var m in (pet['metrics'] as List? ?? [])) {
        await prefs.setBool(m['key'], m['enabled']);
      }
      await prefs.setBool('advice_notif_$id', pet['advice_enabled'] ?? true);
    }

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
  }

  // --- Notification scheduling helpers ---

  void _scheduleFeedingSlot(dynamic pet, dynamic slot) {
    final parts = (slot['time'] as String).split(':');
    _notif.scheduleDailyAt(
      id: NotificationService.feedingId(pet['pet_id'] as int, slot['time'] as String),
      title: 'Feeding Reminder',
      body: 'Time to feed ${pet['pet_first_name']}!',
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  void _cancelFeedingSlot(dynamic pet, dynamic slot) {
    _notif.cancel(NotificationService.feedingId(pet['pet_id'] as int, slot['time'] as String));
  }

  Future<void> _changeFeedingTime(dynamic pet, dynamic slot, TimeOfDay newTime) async {
    final prefs = await SharedPreferences.getInstance();
    final int petId = pet['pet_id'] as int;
    final String oldTimeStr = slot['time'] as String;
    final String baseId = slot['baseId'] as String? ?? '';
    final bool repeatDaily = slot['repeatDaily'] as bool? ?? true;
    final String newTimeStr =
        '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';

    _notif.cancel(NotificationService.feedingId(petId, oldTimeStr));
    await prefs.remove(slot['key'] as String);

    // Update offline_feeding_schedule, creating entries if none exist yet
    final existingJson = prefs.getString('offline_feeding_schedule');
    final List<dynamic> entries =
        existingJson != null ? jsonDecode(existingJson) : [];

    int existingWeekday = 0;
    for (var item in entries) {
      if (item['petId'] == petId) {
        final eid = (item['event']['id'] as String?) ?? '';
        if (eid.replaceAll(RegExp(r'_[0-6]$'), '') == baseId) {
          existingWeekday = item['weekday'] as int? ?? 0;
          break;
        }
      }
    }
    entries.removeWhere((item) {
      if (item['petId'] != petId) return false;
      final eid = (item['event']['id'] as String?) ?? '';
      return eid.replaceAll(RegExp(r'_[0-6]$'), '') == baseId;
    });

    if (repeatDaily) {
      for (int d = 0; d < 7; d++) {
        entries.add({
          'petId': petId,
          'weekday': d,
          'event': {
            'id': '${baseId}_$d',
            'type': 0,
            'name': slot['label'] as String,
            'hour': newTime.hour,
            'minute': newTime.minute,
            'petId': petId,
            'repeatDaily': true,
            'endDate': null,
          },
        });
      }
    } else {
      entries.add({
        'petId': petId,
        'weekday': existingWeekday,
        'event': {
          'id': baseId,
          'type': 0,
          'name': slot['label'] as String,
          'hour': newTime.hour,
          'minute': newTime.minute,
          'petId': petId,
          'repeatDaily': false,
          'endDate': null,
        },
      });
    }

    await prefs.setString('offline_feeding_schedule', jsonEncode(entries));

    final newKey = 'feeding_notif_${petId}_$newTimeStr';
    await prefs.setBool(newKey, slot['enabled'] as bool? ?? true);

    setState(() {
      slot['time'] = newTimeStr;
      slot['key'] = newKey;
    });

    if (_feeding &&
        (pet['reminder_enabled'] as bool? ?? true) &&
        (slot['enabled'] as bool? ?? true)) {
      _scheduleFeedingSlot(pet, slot);
    }
  }

  void _scheduleMetricsPet(dynamic pet) {
    _notif.scheduleDailyAt(
      id: NotificationService.metricsId(pet['pet_id'] as int),
      title: 'Metrics Reminder',
      body: "Don't forget to log ${pet['pet_first_name']}'s health metrics today!",
      hour: 20,
      minute: 0,
    );
  }

  void _cancelMetricsPet(dynamic pet) {
    _notif.cancel(NotificationService.metricsId(pet['pet_id'] as int));
  }

  void _scheduleAdvicePet(dynamic pet) {
    _notif.scheduleDailyAt(
      id: NotificationService.adviceId(pet['pet_id'] as int),
      title: 'Pet Care Tip',
      body: 'Check in on ${pet['pet_first_name']}\'s advice in PetSync!',
      hour: _adviceHour,
      minute: _adviceMinute,
    );
  }

  void _cancelAdvicePet(dynamic pet) {
    _notif.cancel(NotificationService.adviceId(pet['pet_id'] as int));
  }

  void _scheduleAppointment(dynamic appt) {
    if (appt['reminder_time'] == null || appt['reminder_date'] == null) return;
    final parts = (appt['reminder_time'] as String).split(':');
    final dateParts = (appt['reminder_date'] as String).split('-');
    final dt = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    _notif.scheduleOnce(
      id: NotificationService.appointmentNotifId(appt['pet_appointment_id'] as int),
      title: 'Appointment Reminder',
      body: appt['appointment_notes'] ?? 'You have a vet appointment coming up!',
      dateTime: dt,
    );
  }

  void _cancelAppointment(dynamic appt) {
    _notif.cancel(NotificationService.appointmentNotifId(appt['pet_appointment_id'] as int));
  }

  void _rescheduleAll() {
    for (var pet in _petsList) {
      final petFeedingOn = _feeding && (pet['reminder_enabled'] as bool? ?? true);
      for (var slot in (pet['times'] as List)) {
        if (petFeedingOn && (slot['enabled'] as bool)) {
          _scheduleFeedingSlot(pet, slot);
        } else {
          _cancelFeedingSlot(pet, slot);
        }
      }

      if (_metrics && (pet['metrics_enabled'] as bool? ?? true)) {
        _scheduleMetricsPet(pet);
      } else {
        _cancelMetricsPet(pet);
      }

      if (_advice && (pet['advice_enabled'] as bool? ?? true)) {
        _scheduleAdvicePet(pet);
      } else {
        _cancelAdvicePet(pet);
      }
    }

    for (var appt in _appointmentsList) {
      if (_appointments && (appt['reminder_enabled'] as bool? ?? false)) {
        _scheduleAppointment(appt);
      } else {
        _cancelAppointment(appt);
      }
    }
  }

  // --- State helpers ---

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
    _saveSettings();
    _rescheduleAll();
  }

  // --- Card builders ---

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
                if (!v) {
                  for (var a in _appointmentsList) { _cancelAppointment(a); }
                } else {
                  for (var a in _appointmentsList) {
                    if (a['reminder_enabled'] == true) _scheduleAppointment(a);
                  }
                }
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
            final petIndex = _petsList.indexWhere((p) => p['pet_id'] == a['pet_id']);
            final petName = petIndex != -1 ? _petsList[petIndex]['pet_first_name'] as String : '';
            final petColor = petIndex != -1 ? _kPetColors[petIndex % _kPetColors.length] : Colors.blueGrey;
            return GestureDetector(
              onTap: _appointments ? () async {
                await _openReminderFlow(a);
                _saveSettings();
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
                          if (petName.isNotEmpty)
                            Text(petName,
                                style: TextStyle(fontSize: 11, color: petColor, fontWeight: FontWeight.w600)),
                          Text(a['appointment_notes'] ?? "Vet Visit",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(a['pet_appointment_date'], style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            (a['reminder_enabled'] ?? false)
                                ? "${a['repeat_type'] ?? 'Once'} • ${a['reminder_time'] ?? ''}"
                                : "Tap to set reminder",
                            style: const TextStyle(
                                fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: a['reminder_enabled'] ?? false,
                      onChanged: _appointments ? (v) {
                        setState(() => a['reminder_enabled'] = v);
                        _saveSettings();
                        if (v) {
                          _scheduleAppointment(a);
                        } else {
                          _cancelAppointment(a);
                        }
                      } : null,
                    ),
                  ],
                ),
              ),
            );
          }),
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
              const Expanded(
                  child: Text("Feeding Schedule", style: TextStyle(fontWeight: FontWeight.bold))),
              Switch(
                value: _feeding,
                onChanged: (v) {
                  setState(() => _feeding = v);
                  _updateMaster();
                  _saveSettings();
                  for (var pet in _petsList) {
                    for (var slot in (pet['times'] as List)) {
                      if (v && (pet['reminder_enabled'] as bool? ?? true) && (slot['enabled'] as bool)) {
                        _scheduleFeedingSlot(pet, slot);
                      } else {
                        _cancelFeedingSlot(pet, slot);
                      }
                    }
                  }
                },
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
              final petEnabled = (pet['reminder_enabled'] as bool? ?? true) && _feeding;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(pet['pet_first_name'],
                              style: TextStyle(fontWeight: FontWeight.w600, color: petColor)),
                        ),
                        Switch(
                          value: petEnabled,
                          onChanged: _feeding ? (v) {
                            setState(() => pet['reminder_enabled'] = v);
                            _saveSettings();
                            for (var slot in (pet['times'] as List)) {
                              if (v && (slot['enabled'] as bool)) {
                                _scheduleFeedingSlot(pet, slot);
                              } else {
                                _cancelFeedingSlot(pet, slot);
                              }
                            }
                          } : null,
                        ),
                      ],
                    ),
                  ),
                  ...pet['times'].map<Widget>((slot) {
                    return ListTile(
                      leading: const Icon(Icons.access_time, size: 18),
                      title: Text(slot['label'] as String),
                      subtitle: OutlinedButton.icon(
                        onPressed: petEnabled ? () async {
                          final parts = (slot['time'] as String).split(':');
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: int.parse(parts[0]),
                              minute: int.parse(parts[1]),
                            ),
                          );
                          if (picked != null) await _changeFeedingTime(pet, slot, picked);
                        } : null,
                        icon: const Icon(Icons.edit, size: 14),
                        label: Text(slot['time'] as String),
                      ),
                      trailing: Switch(
                        value: (slot['enabled'] as bool) && petEnabled,
                        onChanged: petEnabled ? (v) {
                          setState(() => slot['enabled'] = v);
                          _saveSettings();
                          if (v) {
                            _scheduleFeedingSlot(pet, slot);
                          } else {
                            _cancelFeedingSlot(pet, slot);
                          }
                        } : null,
                      ),
                    );
                  }),
                  const Divider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text("Metric Logging Reminders",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Switch(
                value: _metrics,
                onChanged: (v) {
                  setState(() => _metrics = v);
                  _updateMaster();
                  _saveSettings();
                  for (var pet in _petsList) {
                    if (v && (pet['metrics_enabled'] as bool? ?? true)) {
                      _scheduleMetricsPet(pet);
                    } else {
                      _cancelMetricsPet(pet);
                    }
                  }
                },
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _metricsExpanded = !_metricsExpanded),
            child: Text(_metricsExpanded ? "Hide Details" : "View Details"),
          ),
          if (_metricsExpanded)
            ..._petsList.asMap().entries.map((entry) {
              final pet = entry.value;
              final petColor = _kPetColors[entry.key % _kPetColors.length];
              final metrics = (pet['metrics'] as List? ?? []);
              final petEnabled = (pet['metrics_enabled'] as bool? ?? true) && _metrics;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(pet['pet_first_name'],
                              style: TextStyle(fontWeight: FontWeight.w600, color: petColor)),
                        ),
                        Switch(
                          value: petEnabled,
                          onChanged: _metrics ? (v) {
                            setState(() => pet['metrics_enabled'] = v);
                            _saveSettings();
                            if (v) {
                              _scheduleMetricsPet(pet);
                            } else {
                              _cancelMetricsPet(pet);
                            }
                          } : null,
                        ),
                      ],
                    ),
                  ),
                  if (metrics.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Text("No metrics tracked yet.",
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    )
                  else
                    ...metrics.map<Widget>((m) {
                      final enabled = (m['enabled'] as bool) && petEnabled;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.monitor_heart_outlined, size: 18),
                        title: Text(m['name'] as String),
                        trailing: Switch(
                          value: enabled,
                          onChanged: petEnabled ? (v) {
                            setState(() => m['enabled'] = v);
                            _saveSettings();
                          } : null,
                        ),
                      );
                    }),
                  const Divider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAdviceCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text("Advice", style: TextStyle(fontWeight: FontWeight.bold))),
              Switch(
                value: _advice,
                onChanged: (v) {
                  setState(() => _advice = v);
                  _updateMaster();
                  _saveSettings();
                  for (var pet in _petsList) {
                    if (v && (pet['advice_enabled'] as bool? ?? true)) {
                      _scheduleAdvicePet(pet);
                    } else {
                      _cancelAdvicePet(pet);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _advice ? () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _adviceHour, minute: _adviceMinute),
              );
              if (picked != null) {
                setState(() {
                  _adviceHour = picked.hour;
                  _adviceMinute = picked.minute;
                });
                _saveSettings();
                for (var pet in _petsList) {
                  if (_advice && (pet['advice_enabled'] as bool? ?? true)) {
                    _scheduleAdvicePet(pet);
                  }
                }
              }
            } : null,
            icon: const Icon(Icons.access_time, size: 18),
            label: Text(
              'Every day at ${_adviceHour.toString().padLeft(2, '0')}:${_adviceMinute.toString().padLeft(2, '0')}',
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _adviceExpanded = !_adviceExpanded),
            child: Text(_adviceExpanded ? "Hide Details" : "View Details"),
          ),
          if (_adviceExpanded)
            ..._petsList.asMap().entries.map((entry) {
              final pet = entry.value;
              final petColor = _kPetColors[entry.key % _kPetColors.length];
              final petEnabled = (pet['advice_enabled'] as bool? ?? true) && _advice;
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(pet['pet_first_name'],
                          style: TextStyle(fontWeight: FontWeight.w600, color: petColor)),
                    ),
                    Switch(
                      value: petEnabled,
                      onChanged: _advice ? (v) {
                        setState(() => pet['advice_enabled'] = v);
                        _saveSettings();
                        if (v) {
                          _scheduleAdvicePet(pet);
                        } else {
                          _cancelAdvicePet(pet);
                        }
                      } : null,
                    ),
                  ],
                ),
              );
            }),
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
            _buildAdviceCard(),
            _buildMetricsCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('owner_id') ?? 0;
    final data = await _petService.getAllAppointments(ownerId);
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final upcoming = data.where((a) {
      return a['appointment_status'] == 'Scheduled' &&
          (a['pet_appointment_date'] as String).compareTo(today) >= 0;
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
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (appt['reminder_time'] != null) {
      final parts = (appt['reminder_time'] as String).split(':');
      initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ReminderDialog(
        initialTime: initial,
        initialRepeat: appt['repeat_type'] as String? ?? 'Once',
        appointmentDate: appt['pet_appointment_date'] as String,
      ),
    );

    if (result != null) {
      setState(() {
        appt['reminder_enabled'] = true;
        appt['reminder_time'] = result['time'];
        appt['reminder_date'] = result['date'];
        appt['repeat_type'] = result['repeat'];
      });
      if (_appointments) _scheduleAppointment(appt);
    }
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12)),
      child: child,
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String initialRepeat;
  final String appointmentDate;

  const _ReminderDialog({
    required this.initialTime,
    required this.initialRepeat,
    required this.appointmentDate,
  });

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late TimeOfDay _time;
  late String _repeat;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _repeat = widget.initialRepeat;
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _time.format(context);

    return AlertDialog(
      title: const Text('Set Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Reminder time'),
            trailing: Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _time);
              if (picked != null) setState(() => _time = picked);
            },
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Repeat'),
            trailing: DropdownButton<String>(
              value: _repeat,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'Once', child: Text('Once')),
                DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
              ],
              onChanged: (v) => setState(() => _repeat = v!),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
              'date': widget.appointmentDate,
              'repeat': _repeat,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

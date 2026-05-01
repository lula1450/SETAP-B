import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/services/pet_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final PetService _petService = PetService();

  bool _allNotifications = true;
  bool _appointments = true;
  bool _feeding = true;
  bool _advice = true;
  bool _metrics = true;

  List<dynamic> _appointmentsList = [];
  bool _appointmentsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppointments();
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

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notif_appointments', _appointments);
    await prefs.setBool('notif_feeding', _feeding);
    await prefs.setBool('notif_advice', _advice);
    await prefs.setBool('notif_metrics', _metrics);

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings saved")),
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

  void _updateMaster() {
    _allNotifications = _appointments && _feeding && _advice && _metrics;
  }

  void _toggleAll(bool val) {
    setState(() {
      _allNotifications = val;
      _appointments = val;
      _feeding = val;
      _advice = val;
      _metrics = val;
    });
  }

  Future<void> _openReminderFlow(dynamic appt) async {
    if (!_appointments) return;

    String repeat = appt['repeat_type'] ?? "Once";

    final selectedRepeat = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Repeat Reminder"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  value: "Once",
                  groupValue: repeat,
                  title: const Text("Once"),
                  onChanged: (v) => setStateDialog(() => repeat = v!),
                ),
                RadioListTile(
                  value: "Daily",
                  groupValue: repeat,
                  title: const Text("Daily"),
                  onChanged: (v) => setStateDialog(() => repeat = v!),
                ),
                RadioListTile(
                  value: "Weekly",
                  groupValue: repeat,
                  title: const Text("Weekly"),
                  onChanged: (v) => setStateDialog(() => repeat = v!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, repeat),
              child: const Text("Next")),
        ],
      ),
    );

    if (selectedRepeat == null) return;

    DateTime? chosenDate;

    if (selectedRepeat == "Once") {
      final appointmentDate =
          DateTime.parse(appt['pet_appointment_date']);

      chosenDate = await showDatePicker(
        context: context,
        initialDate: appointmentDate.subtract(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: appointmentDate.subtract(const Duration(days: 1)),
      );

      if (chosenDate == null) return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      appt['reminder_enabled'] = true;
      appt['repeat_type'] = selectedRepeat;

      appt['reminder_time'] =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

      appt['reminder_date'] = chosenDate == null
          ? null
          : "${chosenDate.year}-${chosenDate.month.toString().padLeft(2, '0')}-${chosenDate.day.toString().padLeft(2, '0')}";
    });
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }

  Widget _toggle(String title, bool value, Function(bool) onChanged) {
    return _card(
      Row(
        children: [
          Expanded(child: Text(title)),
          Switch(value: value, onChanged: onChanged),
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
              child: Text(
                "Appointment Reminders",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Switch(
              value: _appointments,
              onChanged: (v) => setState(() => _appointments = v),
            )
          ],
        ),

        TextButton(
          onPressed: () => setState(
              () => _appointmentsExpanded = !_appointmentsExpanded),
          child: Text(
            _appointmentsExpanded
                ? "Hide Appointments"
                : "View Appointments",
          ),
        ),

        if (_appointmentsExpanded)
          ..._appointmentsList.map((a) {
            return GestureDetector(
              onTap: _appointments ? () => _openReminderFlow(a) : null,
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
                          Text(
                            a['appointment_notes'] ?? "Vet Visit",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Text(
                            a['pet_appointment_date'],
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (a['reminder_enabled'] ?? false)
                                ? "${a['repeat_type'] ?? 'Once'} • ${a['reminder_time'] ?? ''}"
                                : "Set reminder",
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: a['reminder_enabled'] ?? false,
                      onChanged: _appointments
                          ? (v) {
                              setState(() {
                                a['reminder_enabled'] = v;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );

    return Stack(
      children: [
        _card(content),
        if (!_appointments)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),
      ],
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
            _toggle("Feeding", _feeding,
                (v) => setState(() => _feeding = v)),
            _toggle("Advice", _advice,
                (v) => setState(() => _advice = v)),
            _toggle("Metrics", _metrics,
                (v) => setState(() => _metrics = v)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text("Save Settings"),
            )
          ],
        ),
      ),
    );
  }
}
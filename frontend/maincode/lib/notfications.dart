import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/services/pet_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  final PetService _petService = PetService();

  bool _allNotifications = true;
  bool _appointments = true;
  bool _feeding = true;
  bool _advice = true;
  bool _metrics = true;

  List<dynamic> _appointmentsList = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUpcomingAppointments();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _appointments = prefs.getBool('notif_appointments') ?? true;
      _feeding = prefs.getBool('notif_feeding') ?? true;
      _advice = prefs.getBool('notif_advice') ?? true;
      _metrics = prefs.getBool('notif_metrics') ?? true;

      _updateMasterToggle();
    });
  }

  Future<void> _loadUpcomingAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final int ownerId = prefs.getInt('owner_id') ?? 0;

    final data = await _petService.getAllAppointments(ownerId);

    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final upcoming = data.where((a) {
      return a['appointment_status'] == 'Scheduled' &&
          (a['pet_appointment_date'] as String).compareTo(today) >= 0;
    }).toList();

    upcoming.sort((a, b) =>
        a['pet_appointment_date'].compareTo(b['pet_appointment_date']));

    setState(() {
      _appointmentsList = upcoming;

      for (var appt in _appointmentsList) {
        appt['reminder_enabled'] = appt['reminder_enabled'] ?? true;
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notif_appointments', _appointments);
    await prefs.setBool('notif_feeding', _feeding);
    await prefs.setBool('notif_advice', _advice);
    await prefs.setBool('notif_metrics', _metrics);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification settings saved")),
    );
  }

  void _toggleAll(bool value) {
    setState(() {
      _allNotifications = value;
      _appointments = value;
      _feeding = value;
      _advice = value;
      _metrics = value;
    });
  }

  void _updateMasterToggle() {
    _allNotifications =
        _appointments && _feeding && _advice && _metrics;
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOptionCard({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return _buildCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF8BAEAE),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Appointment Reminders",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _appointments,
                activeColor: const Color(0xFF8BAEAE),
                onChanged: (val) {
                  setState(() {
                    _appointments = val;
                    _updateMasterToggle();
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<dynamic>(
            isExpanded: true,
            decoration: InputDecoration(
              hintText: "View Upcoming Appointments",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _appointmentsList.map((appt) {
              return DropdownMenuItem<dynamic>(
                value: appt,
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, menuSetState) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${appt['pet_appointment_date']} - ${appt['appointment_notes'] ?? 'Vet Visit'}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Switch(
                          value: appt['reminder_enabled'],
                          activeColor: const Color(0xFF8BAEAE),
                          onChanged: (val) {
                            setState(() {
                              appt['reminder_enabled'] = val;
                            });

                            menuSetState(() {});
                          },
                        ),
                      ],
                    );
                  },
                ),
              );
            }).toList(),
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8BAEAE),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Enable All Notifications",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: _allNotifications,
                      activeColor: const Color(0xFF8BAEAE),
                      onChanged: _toggleAll,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _buildAppointmentCard(),

              _buildOptionCard(
                title: "Feeding Reminders",
                value: _feeding,
                onChanged: (val) {
                  setState(() {
                    _feeding = val;
                    _updateMasterToggle();
                  });
                },
              ),

              _buildOptionCard(
                title: "Daily Advice Reminders",
                value: _advice,
                onChanged: (val) {
                  setState(() {
                    _advice = val;
                    _updateMasterToggle();
                  });
                },
              ),

              _buildOptionCard(
                title: "Log Daily Metrics Reminders",
                value: _metrics,
                onChanged: (val) {
                  setState(() {
                    _metrics = val;
                    _updateMasterToggle();
                  });
                },
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BAEAE),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 40,
                  ),
                ),
                child: const Text(
                  "Save Settings",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {

  bool _allNotifications = true;

  bool _appointments = true;
  bool _feeding = true;
  bool _advice = true;
  bool _metrics = true; // NEW

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _appointments = prefs.getBool('notif_appointments') ?? true;
      _feeding = prefs.getBool('notif_feeding') ?? true;
      _advice = prefs.getBool('notif_advice') ?? true;
      _metrics = prefs.getBool('notif_metrics') ?? true; // NEW

      _updateMasterToggle();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notif_appointments', _appointments);
    await prefs.setBool('notif_feeding', _feeding);
    await prefs.setBool('notif_advice', _advice);
    await prefs.setBool('notif_metrics', _metrics); // NEW

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
      _metrics = value; // NEW
    });
  }

  void _updateMasterToggle() {
    _allNotifications =
        _appointments && _feeding && _advice && _metrics; // UPDATED
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(2, 2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
              // MASTER
              _buildCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Enable All Notifications",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch(
                      value: _allNotifications,
                      activeColor: const Color(0xFF8BAEAE),
                      onChanged: _toggleAll,
                    )
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // OPTIONS
              _buildOptionCard(
                title: "Appointment Reminders",
                value: _appointments,
                onChanged: (val) {
                  setState(() {
                    _appointments = val;
                    _updateMasterToggle();
                  });
                },
              ),

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

              // NEW OPTION
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                child: const Text("Save Settings",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
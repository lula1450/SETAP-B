import 'package:flutter/material.dart';
import 'package:maincode/screens/login_page.dart';
import 'package:maincode/screens/edit_profile.dart';
import 'package:maincode/screens/notfications.dart';
import 'package:maincode/screens/report_history.dart';
import 'package:maincode/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Your account will be scheduled for permanent deletion in 30 days. "
          "You can cancel by logging back in during that period.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              navigator.pop();
              final prefs = await SharedPreferences.getInstance();
              final ownerId = prefs.getInt('owner_id');
              if (ownerId == null) return;

              final purgeAt = await AuthService().deleteAccount(ownerId);
              if (purgeAt == null) return;

              await prefs.clear();

              String dateLabel = purgeAt;
              final parsed = DateTime.tryParse(purgeAt);
              if (parsed != null) {
                dateLabel =
                    '${parsed.day.toString().padLeft(2, '0')}/'
                    '${parsed.month.toString().padLeft(2, '0')}/'
                    '${parsed.year}';
              }

              if (navigator.context.mounted) {
                showDialog(
                  context: navigator.context,
                  barrierDismissible: false,
                  builder: (ctx2) => AlertDialog(
                    title: const Text("Deletion Scheduled"),
                    content: Text(
                      "Your account has been scheduled for permanent deletion on $dateLabel.\n\n"
                      "You have 30 days to change your mind — just log back in and cancel.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => navigator.pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 139, 174, 174),
            ),
            child: Text(
              'Settings',
              style: TextStyle(color: Colors.black, fontSize: 24),
            ),
          ),
          _drawerTile(
            context,
            Icons.person,
            'Edit Profile',
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),
          _drawerTile(
            context,
            Icons.notifications,
            'Notifications',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
          _drawerTile(
            context,
            Icons.palette,
            'Report History',
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportHistoryPage(),
                ),
              );
            },
          ),
          _drawerTile(
            context,
            Icons.logout,
            'Logout',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('owner_id');
                        await prefs.remove('owner_email');
                        await prefs.remove('owner_first_name');
                        await prefs.remove('owner_last_name');
                        await prefs.remove('auth_token');
                        await prefs.remove('show_photo_hint');
                        await prefs.remove('show_metrics_hint');
                        await prefs.remove('show_appointment_hint');
                        await prefs.remove('show_advice_hint');
                        await prefs.remove('show_report_hint');
                        await prefs.remove('show_recently_logged_hint');
                        await prefs.remove('show_health_records_hint');
                        await prefs.remove('show_feeding_hint');
                        await prefs.remove('show_vet_hint');
                        await prefs.remove('show_find_out_more_hint');
                        await prefs.remove('show_settings_hint');
                        await prefs.remove('show_change_pet_hint');
                        navigator.pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
          ),
          _drawerTile(
            context,
            Icons.delete_forever,
            'Delete Account',
            color: Colors.red,
            onTap: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context,
    IconData icon,
    String title, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:maincode/login_page.dart';
import 'package:maincode/edit_profile.dart';
import 'package:maincode/notfications.dart';
import 'package:maincode/report_history.dart';
import 'package:maincode/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
        ),
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
              final ownerId = prefs.getInt('owner_id');
              if (ownerId != null) {
                final success = await AuthService().deleteAccount(ownerId);
                if (success) {
                  await prefs.clear();
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
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
            Icons.palette,
            'Notifications',
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
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
                        await prefs.clear();
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

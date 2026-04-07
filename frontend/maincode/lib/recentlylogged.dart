import 'package:flutter/material.dart';
import 'package:maincode/services/pet_service.dart';

class RecentlyLoggedDataPage extends StatefulWidget {
  final int petId;
  final String petName;

  const RecentlyLoggedDataPage({
    super.key, 
    required this.petId, 
    required this.petName
  });

  @override
  State<RecentlyLoggedDataPage> createState() => _RecentlyLoggedDataPageState();
}

class _RecentlyLoggedDataPageState extends State<RecentlyLoggedDataPage> {
  final PetService _service = PetService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildDrawer(),
      appBar: AppBar(
        title: Text("${widget.petName}'s Logged Data"),
        backgroundColor: const Color(0xFF8BAEAE),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _service.getPetHistory(widget.petId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading history'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data logged yet.'));
          }

          final logs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF8BAEAE).withValues(alpha: 0.2),
                    child: _getIcon(log['metric']),
                  ),
                  title: Text(
                    log['metric'].toString().replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(log['time']),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${log['value']}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${log['unit']}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getIcon(String metric) {
    switch (metric.toLowerCase()) {
      case 'weight': return const Icon(Icons.fitness_center, color: Color(0xFF8BAEAE));
      case 'water_intake': return const Icon(Icons.water_drop, color: Colors.blue);
      case 'appetite': return const Icon(Icons.restaurant, color: Colors.orange);
      default: return const Icon(Icons.analytics, color: Colors.grey);
    }
  }

  // --- Settings Drawer (copied from Dashboard) ---
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromARGB(255, 139, 174, 174)),
            child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _drawerTile(Icons.person, 'Edit Profile'),
          _drawerTile(Icons.notifications, 'Notifications'),
          _drawerTile(Icons.palette, 'Report History'),
          _drawerTile(Icons.logout, 'Logout'),
          _drawerTile(Icons.delete_forever, 'Delete Account', color: Colors.red),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        if (title == 'Delete Account') {
          _showDeleteConfirmation();
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("Permanently delete profile and pet data?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: const Text("Delete", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
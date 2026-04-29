import 'package:flutter/material.dart';
import 'package:maincode/widgets/app_drawer.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: const Center(
        child: Text("No notifications yet"),
      ),
    );
  }
}
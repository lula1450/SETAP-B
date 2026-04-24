import 'package:flutter/material.dart';

// Entry point of the application
void main() => runApp(const PetCareApp());

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const FeedingSchedulePage(),
    );
  }
}

// Model classes for pets and events
enum EventType { feeding, vet, other }

extension EventTypeExtension on EventType {
  String get label {
    switch (this) {
      case EventType.feeding: return 'Feeding';
      case EventType.vet:     return 'Vet appointment';
      case EventType.other:   return 'Other';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EventType.feeding: return const Color(0xFFE1F5EE);
      case EventType.vet:     return const Color(0xFFE6F1FB);
      case EventType.other:   return const Color(0xFFFAECE7);
    }
  }

  Color get textColor {
    switch (this) {
      case EventType.feeding: return const Color(0xFF0F6E56);
      case EventType.vet:     return const Color(0xFF185FA5);
      case EventType.other:   return const Color(0xFF993C1D);
    }
  }

  Color get borderColor {
    switch (this) {
      case EventType.feeding: return const Color(0xFF5DCAA5);
      case EventType.vet:     return const Color(0xFF85B7EB);
      case EventType.other:   return const Color(0xFFF0997B);
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.feeding: return Icons.restaurant_rounded;
      case EventType.vet:     return Icons.local_hospital_rounded;
      case EventType.other:   return Icons.event_note_rounded;
    }
  }
}

class Pet {
  final String id;
  final String name;
  final String species;

  const Pet({required this.id, required this.name, required this.species});
}

class PetEvent {
  final String id;
  final EventType type;
  final String name;
  final TimeOfDay time;
  final String petId;

  PetEvent({
    required this.id,
    required this.type,
    required this.name,
    required this.time,
    required this.petId,
  });

  PetEvent copyWith({
    String? id,
    EventType? type,
    String? name,
    TimeOfDay? time,
    String? petId,
  }) {
    return PetEvent(
      id:    id    ?? this.id,
      type:  type  ?? this.type,
      name:  name  ?? this.name,
      time:  time  ?? this.time,
      petId: petId ?? this.petId,
    );
  }
}

// Helper functions for generating unique IDs and formatting dates/times
String _uid() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmt12(TimeOfDay t) {
  final hour   = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final min    = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'am' : 'pm';
  return '$hour:$min $period';
}

// Main page for displaying and managing the feeding schedule
class FeedingSchedulePage extends StatefulWidget {
  const FeedingSchedulePage({super.key});

  @override
  State<FeedingSchedulePage> createState() => _FeedingSchedulePageState();
}

// State class for the FeedingSchedulePage, managing the active pet, week offset, and events
class _FeedingSchedulePageState extends State<FeedingSchedulePage> {
  static const List<Pet> _pets = [
    Pet(id: 'buddy',    name: 'Buddy',    species: 'Dog'),
    Pet(id: 'whiskers', name: 'Whiskers', species: 'Cat'),
  ];

  String _activePetId = 'buddy';
  int    _weekOffset  = 0;

  final Map<String, Map<String, List<PetEvent>>> _events = {
    'buddy':    {},
    'whiskers': {},
  };

  @override
  void initState() {
    super.initState();
    _seedDefaults();
  }
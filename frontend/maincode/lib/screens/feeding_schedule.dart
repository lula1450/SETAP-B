// This page displays and manages a household feeding schedule across all pets.
// Supports daily or weekly recurring feeding events with optional end dates.
// Merges backend seeded data with user modifications stored locally, with proper conflict resolution.
// Features calendar view, week navigation, upcoming feedings preview, and notification scheduling.

import 'package:flutter/material.dart';
import 'package:maincode/screens/route_observer.dart';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:maincode/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Entry point of the app
void main() => runApp(const PetCareApp());

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        endDrawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Household Feeding Schedule'),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        body: const FeedingSchedulePage(),
      ),
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────

/// Only feeding-related event types are supported on this page.
enum EventType { feeding, refillFeeder }

extension EventTypeExtension on EventType {
  String get label {
    switch (this) {
      case EventType.feeding:
        return 'Feeding';
      case EventType.refillFeeder:
        return 'Refill Feeder';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EventType.feeding:
        return const Color(0xFFE1F5EE);
      case EventType.refillFeeder:
        return const Color(0xFFFFF8E1);
    }
  }

  Color get textColor {
    switch (this) {
      case EventType.feeding:
        return const Color(0xFF0F6E56);
      case EventType.refillFeeder:
        return const Color(0xFF7B5800);
    }
  }

  Color get borderColor {
    switch (this) {
      case EventType.feeding:
        return const Color(0xFF5DCAA5);
      case EventType.refillFeeder:
        return const Color(0xFFFFCC02);
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.feeding:
        return Icons.restaurant_rounded;
      case EventType.refillFeeder:
        return Icons.autorenew_rounded;
    }
  }
}

/// Pet model populated from the backend via [PetService].
class Pet {
  final int id;
  final String name;
  final String species;

  const Pet({required this.id, required this.name, required this.species});

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['pet_id'] as int,
      name: json['pet_first_name'] as String? ?? 'Unknown',
      species: json['species_name'] as String? ?? '',
    );
  }
}

class PetEvent {
  final String id;
  final EventType type;
  final String name;
  final TimeOfDay time;
  final int petId;
  final bool repeatDaily;     // true = every day, false = same weekday only
  final DateTime? endDate;    // null = repeats indefinitely

  PetEvent({
    required this.id,
    required this.type,
    required this.name,
    required this.time,
    required this.petId,
    this.repeatDaily = false,
    this.endDate,
  });

  PetEvent copyWith({
    String? id,
    EventType? type,
    String? name,
    TimeOfDay? time,
    int? petId,
    bool? repeatDaily,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return PetEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      time: time ?? this.time,
      petId: petId ?? this.petId,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'name': name,
    'hour': time.hour,
    'minute': time.minute,
    'petId': petId,
    'repeatDaily': repeatDaily,
    'endDate': endDate?.toIso8601String(),
  };

  // Add this fromJson factory
  factory PetEvent.fromJson(Map<String, dynamic> json) => PetEvent(
    id: json['id'],
    type: EventType.values[json['type']],
    name: json['name'],
    time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    petId: json['petId'],
    repeatDaily: json['repeatDaily'] ?? false,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
  );
}

// ─── Per-pet colours — same list as dashboard _getPetColor ───────────────────

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

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _uid() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmt24(TimeOfDay t) {
  final hour = t.hour.toString().padLeft(2, '0');
  final min = t.minute.toString().padLeft(2, '0');
  return '$hour:$min';
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class FeedingSchedulePage extends StatefulWidget {
  const FeedingSchedulePage({super.key});

  @override
  State<FeedingSchedulePage> createState() => _FeedingSchedulePageState();
}

class _FeedingSchedulePageState extends State<FeedingSchedulePage> with RouteAware {
  final PetService _service = PetService();
  final NotificationService _notif = NotificationService();

  List<Pet> _pets = [];
  int? _activePetId;
  int _weekOffset = 0;
  bool _isLoading = true;
  final ScrollController _calendarScroll = ScrollController();
  final ScrollController _petTabScroll = ScrollController();

  // recurring[petId][weekday 0=Mon..6=Sun] = list of PetEvent (repeats every week)
  final Map<int, Map<int, List<PetEvent>>> _recurring = {};

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _calendarScroll.dispose();
    _petTabScroll.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadPets();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  /// Loads pets and feeding schedules from backend, then overlays local modifications from SharedPreferences.
  /// Merges two data sources: (1) backend seeded schedules, (2) user offline edits stored locally.
  /// Backend duplicates are removed when a local version with same ID exists (local takes precedence).
  /// Tracks deleted backend entries to prevent re-insertion on reload.
  Future<void> _loadPets() async {
  setState(() => _isLoading = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    final int ownerId = prefs.getInt('owner_id') ?? 0;

    _recurring.clear(); // Start fresh to prevent duplication

    final rawPets = await _service.getOwnerPets(ownerId);
    if (!mounted) return;
    final pets = rawPets.map((j) => Pet.fromJson(j as Map<String, dynamic>)).toList();

    final deletedIds = prefs.getStringList('deleted_feeding_ids') ?? [];

    // --- STEP 1: LOAD BACKEND SEEDED DATA ---
    // Backend sends repeating schedules with food_name indicating daily vs weekly (contains "weekly")
    for (final p in pets) {
      _recurring.putIfAbsent(p.id, () => {});
      try {
        final schedules = await _service.getFeedingSchedules(p.id);
        for (final s in schedules) {
          if (deletedIds.contains('backend_${s['feeding_schedule_id']}')) continue;
          final raw = s['feeding_time'] as String? ?? '';
          TimeOfDay t = const TimeOfDay(hour: 8, minute: 0);
          int weekday = 0; 
          
          try {
            // Backend often sends "YYYY-MM-DDTHH:mm:ss" format
            final dt = DateTime.parse(raw);
            t = TimeOfDay(hour: dt.hour, minute: dt.minute);
            weekday = dt.weekday - 1; // 1=Mon→0, 7=Sun→6
          } catch (_) {
            try {
              // Fallback for "HH:mm:ss" format
              final parts = raw.split('T').last.split(':');
              t = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
            } catch (_) {}
          }

          // Seeded data logic: daily vs specific weekday based on food_name
          final foodName = (s['food_name'] as String? ?? '').toLowerCase();
          final isWeekly = foodName.contains('weekly');
          final event = PetEvent(
            id: 'backend_${s['feeding_schedule_id']}',
            type: EventType.feeding,
            name: s['food_name'] as String? ?? 'Feed',
            time: t,
            petId: p.id,
            repeatDaily: !isWeekly,
          );

          // If weekly: insert only on specific weekday; if daily: insert on all 7 days
          if (isWeekly) {
            _recurring[p.id]!.putIfAbsent(weekday, () => []).add(event);
          } else {
            for (int d = 0; d < 7; d++) {
              _recurring[p.id]!.putIfAbsent(d, () => []).add(event.copyWith(id: '${event.id}_$d'));
            }
          }
        }
      } catch (e) {
        debugPrint('Backend fetch failed for pet ${p.id}: $e');
      }
    }

    // --- STEP 2: OVERLAY LOCAL STORAGE (USER MODIFICATIONS) ---
    // User edits are stored locally and take precedence over backend dupes
    final localData = prefs.getString('offline_feeding_schedule');
    if (localData != null) {
      final List<dynamic> decoded = jsonDecode(localData);
      for (var item in decoded) {
        final int petId = item['petId'];
        final int weekday = item['weekday'];
        final event = PetEvent.fromJson(item['event']);
        
        _recurring.putIfAbsent(petId, () => {});
        _recurring[petId]!.putIfAbsent(weekday, () => []);

        // Conflict resolution: If a local version exists, it overwrites backend duplicate with same ID
        _recurring[petId]![weekday]!.removeWhere((e) => e.id == event.id);
        _recurring[petId]![weekday]!.add(event);
      }
    }

    setState(() {
      _pets = pets;
      if (pets.isNotEmpty) _activePetId = pets.first.id;
    });
    _scrollToToday();
  } catch (e) {
    debugPrint('Global load error: $e');
  }
  setState(() => _isLoading = false);
}

  void _scrollToToday() {
    if (_weekOffset != 0) return;
    final dayIndex = DateTime.now().weekday - 1; // 0=Mon..6=Sun
    if (dayIndex == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_calendarScroll.hasClients) return;
      const columnWidth = 700.0 / 7;
      final offset = (dayIndex * columnWidth).clamp(0.0, _calendarScroll.position.maxScrollExtent);
      _calendarScroll.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  // ── Week helpers ──────────────────────────────────────────────────────────

  DateTime get _weekStart {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final clean = DateTime(monday.year, monday.month, monday.day);
    return clean.add(Duration(days: _weekOffset * 7));
  }

  void _shiftWeek(int dir) {
    setState(() {
      _weekOffset = dir == 0 ? 0 : _weekOffset + dir;
    });
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    final today = DateTime.now();
    final todayMonday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final pickedMonday = DateTime(picked.year, picked.month, picked.day)
        .subtract(Duration(days: picked.weekday - 1));
    setState(() {
      _weekOffset = pickedMonday.difference(todayMonday).inDays ~/ 7;
    });
  }

  // ── Event CRUD ────────────────────────────────────────────────────────────

  int _weekdayFromKey(String dayKey) {
    final parts = dayKey.split('-');
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return d.weekday - 1; // 1=Mon→0 … 7=Sun→6
  }

  DateTime _dateFromKey(String dayKey) {
    final parts = dayKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// Filters events for a specific day by: (1) extracting weekday from dayKey,
  /// (2) checking end date hasn't passed, (3) sorting by time ascending.
  List<PetEvent> _eventsForDay(int petId, String dayKey) {
    final weekday = _weekdayFromKey(dayKey);
    final date = _dateFromKey(dayKey);
    final petMap = _recurring[petId];
    final raw = petMap == null ? <PetEvent>[] : (petMap[weekday] ?? <PetEvent>[]);
    // Filter out events whose end date has passed
    final list = raw
        .where((e) => e.endDate == null || !date.isAfter(e.endDate!))
        .toList();
    // Sort events by time (earliest first)
    list.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
    return list;
  }

  /// Inserts or updates an event by: (1) extracting base ID (removing weekday suffix),
  /// (2) removing all copies from all weekdays, (3) re-inserting based on repeat mode,
  /// (4) persisting to SharedPreferences, (5) scheduling end-date notification.
  void _upsertEvent(PetEvent ev, String dayKey) {
    final String baseId = ev.id.replaceAll(RegExp(r'_[0-6]$'), '');

    setState(() {
      final petMap = _recurring[ev.petId] ??= {};

      // Remove all copies of this event from every weekday slot
      // Strip the weekday suffix (_0 … _6) to get the base ID.
      petMap.forEach((weekday, list) {
        list.removeWhere((existingEvent) {
          final existingBase = existingEvent.id.replaceAll(RegExp(r'_[0-6]$'), '');
          return existingBase == baseId;
        });
      });

      // Re-insert the updated event based on repeat mode
      if (ev.repeatDaily) {
        // If daily, insert into all 7 days (0-6) with weekday suffix
        for (int d = 0; d < 7; d++) {
          petMap.putIfAbsent(d, () => []).add(
            ev.copyWith(id: '${baseId}_$d')
          );
        }
      } else {
        // If weekly, only insert into the current weekday without suffix
        final weekday = _weekdayFromKey(dayKey);
        petMap.putIfAbsent(weekday, () => []).add(ev.copyWith(id: baseId));
      }
    });

    // Persist changes to local storage
    _saveToLocal();
    _scheduleEndDateNotification(ev, baseId);
  }

  void _scheduleEndDateNotification(PetEvent ev, String baseId) async {
    if (ev.endDate != null) {
      final pet = _pets.firstWhere((p) => p.id == ev.petId,
          orElse: () => const Pet(id: 0, name: 'Your pet', species: ''));
      final endDateTime = DateTime(
          ev.endDate!.year, ev.endDate!.month, ev.endDate!.day, 9, 0);
      await _notif.scheduleOnce(
        id: NotificationService.feedingEndId(baseId),
        title: "${pet.name}'s feeding schedule",
        body: "'${ev.name}' ends today.",
        dateTime: endDateTime,
      );
    } else {
      await _notif.cancel(NotificationService.feedingEndId(baseId));
    }
  }

  /// Deletes an event: (1) finds it before removal to get notification details,
  /// (2) if backend event, deletes from server and stores ID in deleted list,
  /// (3) cancels scheduled notifications, (4) removes from state, (5) persists changes.
  void _deleteEvent(int petId, String dayKey, String eventId) async {
    final String baseId = eventId.replaceAll(RegExp(r'_[0-6]$'), '');

    // Find the event before removing it so we can cancel its notification
    PetEvent? found;
    _recurring[petId]?.forEach((_, list) {
      for (final e in list) {
        if (e.id.replaceAll(RegExp(r'_[0-6]$'), '') == baseId) {
          found = e;
          return;
        }
      }
    });

    final prefs = await SharedPreferences.getInstance();

    // If backend event: delete from server and mark locally so it doesn't re-appear on reload
    if (baseId.startsWith('backend_')) {
      final scheduleId = int.tryParse(baseId.replaceFirst('backend_', ''));
      if (scheduleId != null) {
        await _service.deleteFeedingSchedule(scheduleId);
      }
      final deleted = prefs.getStringList('deleted_feeding_ids') ?? [];
      if (!deleted.contains(baseId)) {
        deleted.add(baseId);
        await prefs.setStringList('deleted_feeding_ids', deleted);
      }
    }

    // Cancel scheduled notifications for this feeding event
    if (found != null) {
      final timeStr =
          '${found!.time.hour.toString().padLeft(2, '0')}:${found!.time.minute.toString().padLeft(2, '0')}';
      _notif.cancel(NotificationService.feedingId(petId, timeStr));
      _notif.cancel(NotificationService.feedingEndId(baseId));
      await prefs.remove('feeding_notif_${petId}_$timeStr');
    }

    // Remove from state and persist
    setState(() {
      _recurring[petId]?.forEach((_, list) {
        list.removeWhere((e) =>
            e.id.replaceAll(RegExp(r'_[0-6]$'), '') == baseId);
      });
    });
    _saveToLocal();
  }

  Future<void> _openEventDialog({
    PetEvent? existing,
    required String dayKey,
  }) async {
    if (_activePetId == null) return;
    await showDialog(
      context: context,
      builder: (_) => _EventDialog(
        pets: _pets,
        activePetId: _activePetId!,
        existing: existing,
        dayKey: dayKey,
        onSave: (ev) => _upsertEvent(ev, dayKey),
        onDelete: existing == null
            ? null
            : () => _deleteEvent(existing.petId, dayKey, existing.id),
      ),
    );
  }

  /// Flattens the 2D recurring map (petId→weekday→events) into a flat array for JSON storage.
  /// Persists to SharedPreferences for offline access and backup of user modifications.
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
  
  // Flatten the nested map structure for easier storage
    final List<Map<String, dynamic>> flattened = [];
  
    _recurring.forEach((petId, weekdayMap) {
     weekdayMap.forEach((weekday, events) {
       for (var event in events) {
          flattened.add({
           'petId': petId,
           'weekday': weekday,
           'event': event.toJson(),
          });
        }
      });
    });

    await prefs.setString('offline_feeding_schedule', jsonEncode(flattened));
  }

  // ── Upcoming feedings ─────────────────────────────────────────────────────

  /// Scans all pets and finds the next upcoming feeding event.
  /// Returns list of (pet, event, daysUntil) tuples sorted by daysUntil then by time.
  /// Skips today's events that have already passed.
  List<({Pet pet, PetEvent event, int daysUntil})> _getUpcomingFeedings() {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    final result = <({Pet pet, PetEvent event, int daysUntil})>[];

    for (final pet in _pets) {
      PetEvent? nextEvent;
      int? nextDays;

      // Look ahead up to 7 days to find next event
      for (int d = 0; d < 7; d++) {
        final checkDate = now.add(Duration(days: d));
        final dayKey = _dateKey(DateTime(checkDate.year, checkDate.month, checkDate.day));
        final events = _eventsForDay(pet.id, dayKey);

        for (final ev in events) {
          final evMins = ev.time.hour * 60 + ev.time.minute;
          // Skip today's events that have already passed
          if (d == 0 && evMins <= nowMins) continue;
          nextEvent = ev;
          nextDays = d;
          break;
        }
        if (nextEvent != null) break;
      }

      if (nextEvent != null) {
        result.add((pet: pet, event: nextEvent, daysUntil: nextDays!));
      }
    }

    // Sort by daysUntil ascending, then by time ascending
    result.sort((a, b) {
      if (a.daysUntil != b.daysUntil) return a.daysUntil.compareTo(b.daysUntil);
      final aMin = a.event.time.hour * 60 + a.event.time.minute;
      final bMin = b.event.time.hour * 60 + b.event.time.minute;
      return aMin.compareTo(bMin);
    });

    return result;
  }

  Widget _buildUpcomingSection() {
    final upcoming = _getUpcomingFeedings();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Upcoming Feedings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'No upcoming feedings scheduled.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            )
          else
            ...upcoming.map((entry) {
              final petIdx = _pets.indexWhere((p) => p.id == entry.pet.id);
              final petColor = _kPetColors[petIdx % _kPetColors.length];
              final when = entry.daysUntil == 0
                  ? 'Today'
                  : entry.daysUntil == 1
                      ? 'Tomorrow'
                      : () {
                          final d = DateTime.now().add(Duration(days: entry.daysUntil));
                          return '${d.day} ${months[d.month - 1]}';
                        }();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: petColor.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: petColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(entry.event.type.icon, size: 16, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.pet.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                          ),
                          Text(
                            entry.event.name,
                            style: const TextStyle(fontSize: 12, color: Colors.black),
                          ),
                          if (entry.event.endDate != null)
                            Text(
                              'Until ${entry.event.endDate!.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][entry.event.endDate!.month - 1]} ${entry.event.endDate!.year}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt24(entry.event.time),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        Text(
                          when,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ws = _weekStart;
    final we = ws.add(const Duration(days: 6));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final weekLabel =
        '${months[ws.month - 1]} ${ws.day} – ${months[we.month - 1]} ${we.day}, ${we.year}';

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BAEAE),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          children: [
            Text(
              'Household Feeding',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            Text(
              'Schedule',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Gradient background ──
          Positioned.fill(
            child: Container(
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
            ),
          ),
          // ── Main content ──
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Week nav bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_weekOffset == 0)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 3),
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Current Week',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      weekLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _pickWeek,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Pick Week',
                                    style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _shiftWeek(0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Return Current',
                                    style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Pet tabs
                        if (_pets.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: _pets.length > 4
                                ? SizedBox(
                                    height: 42,
                                    child: Stack(
                                      children: [
                                        SingleChildScrollView(
                                          controller: _petTabScroll,
                                          scrollDirection: Axis.horizontal,
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          child: Row(
                                            children: _pets.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final p = entry.value;
                                              final active = p.id == _activePetId;
                                              final petColor = _kPetColors[idx % _kPetColors.length];
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: GestureDetector(
                                                  onTap: () => setState(() => _activePetId = p.id),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 180),
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: active ? petColor : petColor.withValues(alpha: 0.25),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: active ? petColor : petColor.withValues(alpha: 0.5),
                                                        width: active ? 2 : 0.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      p.species.isNotEmpty ? '${p.name} (${p.species})' : p.name,
                                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0, top: 0, bottom: 0,
                                          child: GestureDetector(
                                            onTap: () => _petTabScroll.animateTo(
                                              (_petTabScroll.offset - 150).clamp(0, _petTabScroll.position.maxScrollExtent),
                                              duration: const Duration(milliseconds: 200),
                                              curve: Curves.easeInOut,
                                            ),
                                            child: Container(
                                              width: 24,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [const Color(0xFF8BAEAE).withValues(alpha: 0.35), Colors.transparent],
                                                ),
                                              ),
                                              child: const Icon(Icons.chevron_left, size: 20, color: Colors.black),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0, top: 0, bottom: 0,
                                          child: GestureDetector(
                                            onTap: () => _petTabScroll.animateTo(
                                              (_petTabScroll.offset + 150).clamp(0, _petTabScroll.position.maxScrollExtent),
                                              duration: const Duration(milliseconds: 200),
                                              curve: Curves.easeInOut,
                                            ),
                                            child: Container(
                                              width: 24,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.centerRight,
                                                  end: Alignment.centerLeft,
                                                  colors: [const Color(0xFF8BAEAE).withValues(alpha: 0.35), Colors.transparent],
                                                ),
                                              ),
                                              child: const Icon(Icons.chevron_right, size: 20, color: Colors.black),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: _pets.asMap().entries.map((entry) {
                                        final idx = entry.key;
                                        final p = entry.value;
                                        final active = p.id == _activePetId;
                                        final petColor = _kPetColors[idx % _kPetColors.length];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: GestureDetector(
                                            onTap: () => setState(() => _activePetId = p.id),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 180),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: active ? petColor : petColor.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: active ? petColor : petColor.withValues(alpha: 0.5),
                                                  width: active ? 2 : 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                p.species.isNotEmpty ? '${p.name} (${p.species})' : p.name,
                                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),

                        // Legend
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Row(
                            children: EventType.values.map((t) => Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: t.textColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(t.label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),

                        // Calendar grid — fixed height, horizontal scroll with arrows
                        SizedBox(
                          height: 420,
                          child: _activePetId == null
                              ? const Center(
                                  child: Text(
                                    'No pets found.\nMake sure your account has pets registered.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                )
                              : Stack(
                                  children: [
                                    SingleChildScrollView(
                                      controller: _calendarScroll,
                                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                                      scrollDirection: Axis.horizontal,
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: SizedBox(
                                        width: MediaQuery.of(context).size.width > 700
                                            ? MediaQuery.of(context).size.width - 24
                                            : 700,
                                        child: _CalendarGrid(
                                          weekStart: ws,
                                          activePetId: _activePetId!,
                                          petColorIndex: _pets.indexWhere((p) => p.id == _activePetId),
                                          eventsForDay: _eventsForDay,
                                          onAddTap: (dayKey) => _openEventDialog(dayKey: dayKey),
                                          onEventTap: (ev, dayKey) => _openEventDialog(existing: ev, dayKey: dayKey),
                                        ),
                                      ),
                                    ),
                                    // Left arrow — scroll left, or go to previous week if at start
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 16,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_calendarScroll.hasClients && _calendarScroll.offset <= 0) {
                                            _shiftWeek(-1);
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (_calendarScroll.hasClients) {
                                                _calendarScroll.jumpTo(_calendarScroll.position.maxScrollExtent);
                                              }
                                            });
                                          } else {
                                            _calendarScroll.animateTo(
                                              (_calendarScroll.offset - 200).clamp(0, _calendarScroll.position.maxScrollExtent),
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: 28,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                const Color(0xFF8BAEAE).withValues(alpha: 0.35),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: const Icon(Icons.chevron_left, size: 28, color: Colors.black),
                                        ),
                                      ),
                                    ),
                                    // Right arrow — scroll right, or go to next week if at end
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 16,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_calendarScroll.hasClients && _calendarScroll.offset >= _calendarScroll.position.maxScrollExtent) {
                                            _shiftWeek(1);
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (_calendarScroll.hasClients) {
                                                _calendarScroll.jumpTo(0);
                                              }
                                            });
                                          } else {
                                            _calendarScroll.animateTo(
                                              (_calendarScroll.offset + 200).clamp(0, _calendarScroll.position.maxScrollExtent),
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: 28,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerRight,
                                              end: Alignment.centerLeft,
                                              colors: [
                                                const Color(0xFF8BAEAE).withValues(alpha: 0.35),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: const Icon(Icons.chevron_right, size: 28, color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        // Upcoming feedings
                        _buildUpcomingSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

}

// ─── Calendar Grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime weekStart;
  final int activePetId;
  final int petColorIndex;
  final List<PetEvent> Function(int petId, String dayKey) eventsForDay;
  final void Function(String dayKey) onAddTap;
  final void Function(PetEvent ev, String dayKey) onEventTap;

  const _CalendarGrid({
    required this.weekStart,
    required this.activePetId,
    required this.petColorIndex,
    required this.eventsForDay,
    required this.onAddTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final todayKey = _dateKey(DateTime(today.year, today.month, today.day));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (i) {
        final d = weekStart.add(Duration(days: i));
        final dayKey = _dateKey(d);
        final events = eventsForDay(activePetId, dayKey);
        final isToday = dayKey == todayKey;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Day header
                Column(
                  children: [
                    Text(
                      days[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.white
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? const Color(0xFF8BAEAE)
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                        height: 0.5,
                        color: Colors.white.withValues(alpha: 0.5)),
                  ],
                ),
                const SizedBox(height: 6),

                // Events
                ...events.map(
                  (ev) => _EventChip(
                    event: ev,
                    colorIndex: petColorIndex,
                    onTap: () => onEventTap(ev, dayKey),
                  ),
                ),

                // Add button
                GestureDetector(
                  onTap: () => onAddTap(dayKey),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      border: Border.all(
                        color: Colors.white54,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Event Chip ───────────────────────────────────────────────────────────────

class _EventChip extends StatelessWidget {
  final PetEvent event;
  final int colorIndex;
  final VoidCallback onTap;

  const _EventChip({required this.event, required this.colorIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = _kPetColors[colorIndex % _kPetColors.length];
    final t = event.type;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: base.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: base, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fmt24(event.time),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Icon(t.icon, size: 12, color: Colors.black87),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            if (event.endDate != null) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.event_busy, size: 10, color: Colors.black45),
                  const SizedBox(width: 3),
                  Text(
                    'Until ${event.endDate!.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][event.endDate!.month - 1]}',
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Event Dialog ─────────────────────────────────────────────────────────────

class _EventDialog extends StatefulWidget {
  final List<Pet> pets;
  final int activePetId;
  final PetEvent? existing;
  final String dayKey;
  final void Function(PetEvent ev) onSave;
  final VoidCallback? onDelete;

  const _EventDialog({
    required this.pets,
    required this.activePetId,
    required this.existing,
    required this.dayKey,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late EventType _type;
  late int _petId;
  late TextEditingController _nameCtrl;
  late TimeOfDay _time;
  bool _repeatDaily = false;
  bool _hasEndDate = false;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final ev = widget.existing;
    _type = ev?.type ?? EventType.feeding;
    _petId = ev?.petId ?? widget.activePetId;
    _nameCtrl = TextEditingController(text: ev?.name ?? '');
    _time = ev?.time ?? const TimeOfDay(hour: 8, minute: 0);
    _repeatDaily = ev?.repeatDaily ?? true;
    _endDate = ev?.endDate;
    _hasEndDate = ev?.endDate != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _save() {
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : _type.label;
    widget.onSave(
      PetEvent(
        id: widget.existing?.id ?? _uid(),
        type: _type,
        name: name,
        time: _time,
        petId: _petId,
        repeatDaily: _repeatDaily,
        endDate: _hasEndDate ? _endDate : null,
      ),
    );
    Navigator.of(context).pop();
  }

  void _delete() {
    widget.onDelete?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        widget.existing == null ? 'Add Event' : 'Edit Event',
        style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recurring-edit notice
            if (widget.existing != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8BAEAE), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 14, color: Color(0xFF0F6E56)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Changes will update all ${_repeatDaily ? 'daily' : 'weekly'} occurrences.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0F6E56),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Type
            _Label('Event Type'),
            DropdownButtonFormField<EventType>(
              initialValue: _type,
              decoration: _inputDeco(),
              items: EventType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, size: 16, color: t.textColor),
                          const SizedBox(width: 8),
                          Text(t.label,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),

            // Pet selector (only shown when multiple pets)
            if (widget.pets.length > 1) ...[
              _Label('Pet'),
              DropdownButtonFormField<int>(
                initialValue: _petId,
                decoration: _inputDeco(),
                items: widget.pets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          p.species.isNotEmpty
                              ? '${p.name} (${p.species})'
                              : p.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _petId = v);
                },
              ),
              const SizedBox(height: 12),
            ],

            // Name
            _Label('Label'),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDeco().copyWith(
                hintText: _type == EventType.refillFeeder
                    ? 'e.g. Refill hopper'
                    : 'e.g. Morning feed',
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Refill feeder hint
            if (_type == EventType.refillFeeder)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFFFCC02), width: 0.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.autorenew_rounded,
                        size: 14, color: Color(0xFF7B5800)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reminder to top up the automatic feeder reservoir.',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF7B5800)),
                      ),
                    ),
                  ],
                ),
              ),
            if (_type == EventType.refillFeeder)
              const SizedBox(height: 12),

            // Time
            _Label('Time'),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFFCCCCCC), width: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: Color(0xFF888888)),
                    const SizedBox(width: 8),
                    Text(_fmt24(_time),
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Repeat type
            _Label('Repeats'),
            Row(
              children: [
                for (final option in [
                  (label: 'Daily',  daily: true),
                  (label: 'Weekly', daily: false),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _repeatDaily = option.daily),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _repeatDaily == option.daily
                              ? const Color(0xFF8BAEAE)
                              : Colors.white,
                          border: Border.all(color: const Color(0xFF8BAEAE), width: 1),
                          borderRadius: BorderRadius.horizontal(
                            left: option.daily
                                ? const Radius.circular(8)
                                : Radius.zero,
                            right: option.daily
                                ? Radius.zero
                                : const Radius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(option.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _repeatDaily == option.daily
                                      ? Colors.white
                                      : const Color(0xFF8BAEAE),
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // End date toggle
            _Label('Duration'),
            Row(
              children: [
                for (final option in [
                  (label: 'Forever',      ends: false),
                  (label: 'Ends on date', ends: true),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _hasEndDate = option.ends),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _hasEndDate == option.ends
                              ? const Color(0xFF8BAEAE)
                              : Colors.white,
                          border: Border.all(color: const Color(0xFF8BAEAE), width: 1),
                          borderRadius: BorderRadius.horizontal(
                            left: !option.ends
                                ? const Radius.circular(8)
                                : Radius.zero,
                            right: option.ends
                                ? const Radius.circular(8)
                                : Radius.zero,
                          ),
                        ),
                        child: Center(
                          child: Text(option.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _hasEndDate == option.ends
                                      ? Colors.white
                                      : const Color(0xFF8BAEAE),
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_hasEndDate) ...[
              const SizedBox(height: 10),
              _Label('End date'),
              GestureDetector(
                onTap: _pickEndDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Color(0xFF888888)),
                      const SizedBox(width: 8),
                      Text(
                        _endDate == null
                            ? 'Tap to select a date'
                            : '${_endDate!.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_endDate!.month - 1]} ${_endDate!.year}',
                        style: TextStyle(
                            fontSize: 14,
                            color: _endDate == null
                                ? const Color(0xFF888888)
                                : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: widget.onDelete != null
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(
                foregroundColor: Colors.red[700]),
            child: const Text('Delete'),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF666666))),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8BAEAE),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save'),
        ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDeco() => InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFFCCCCCC), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFFCCCCCC), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFF8BAEAE), width: 1.5),
        ),
      );
}

// ─── Label widget ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
      ),
    );
  }
}

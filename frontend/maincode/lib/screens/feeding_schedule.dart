import 'package:flutter/material.dart';
import 'package:maincode/screens/route_observer.dart';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:maincode/services/pet_service.dart';
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

String _fmt12(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final min = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'am' : 'pm';
  return '$hour:$min $period';
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class FeedingSchedulePage extends StatefulWidget {
  const FeedingSchedulePage({super.key});

  @override
  State<FeedingSchedulePage> createState() => _FeedingSchedulePageState();
}

class _FeedingSchedulePageState extends State<FeedingSchedulePage> with RouteAware {
  final PetService _service = PetService();

  List<Pet> _pets = [];
  int? _activePetId;
  int _weekOffset = 0;
  bool _isLoading = true;

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
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadPets();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadPets() async {
  setState(() => _isLoading = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    final int ownerId = prefs.getInt('owner_id') ?? 0;

    _recurring.clear(); // Start fresh to prevent duplication

    final rawPets = await _service.getOwnerPets(ownerId);
    if (!mounted) return;
    final pets = rawPets.map((j) => Pet.fromJson(j as Map<String, dynamic>)).toList();

    // --- STEP 1: LOAD BACKEND SEEDED DATA ---
    for (final p in pets) {
      _recurring.putIfAbsent(p.id, () => {});
      try {
        final schedules = await _service.getFeedingSchedules(p.id);
        for (final s in schedules) {
          final raw = s['feeding_time'] as String? ?? '';
          TimeOfDay t = const TimeOfDay(hour: 8, minute: 0);
          int weekday = 0; 
          
          try {
            // Backend often sends "YYYY-MM-DDTHH:mm:ss"
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

          // Seeded data logic: daily vs specific weekday
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
    final localData = prefs.getString('offline_feeding_schedule');
    if (localData != null) {
      final List<dynamic> decoded = jsonDecode(localData);
      for (var item in decoded) {
        final int petId = item['petId'];
        final int weekday = item['weekday'];
        final event = PetEvent.fromJson(item['event']);
        
        _recurring.putIfAbsent(petId, () => {});
        _recurring[petId]!.putIfAbsent(weekday, () => []);

        // Prevent duplicates: If a local version exists, it overwrites backend duplicate
        _recurring[petId]![weekday]!.removeWhere((e) => e.id == event.id);
        _recurring[petId]![weekday]!.add(event);
      }
    }

    setState(() {
      _pets = pets;
      if (pets.isNotEmpty) _activePetId = pets.first.id;
    });
  } catch (e) {
    debugPrint('Global load error: $e');
  }
  setState(() => _isLoading = false);
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

  List<PetEvent> _eventsForDay(int petId, String dayKey) {
    final weekday = _weekdayFromKey(dayKey);
    final date = _dateFromKey(dayKey);
    final petMap = _recurring[petId];
    final raw = petMap == null ? <PetEvent>[] : (petMap[weekday] ?? <PetEvent>[]);
    final list = raw
        .where((e) => e.endDate == null || !date.isAfter(e.endDate!))
        .toList();
    list.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
    return list;
  }

  void _upsertEvent(PetEvent ev, String dayKey) {
    setState(() {
      final petMap = _recurring[ev.petId] ??= {};

      // Strip the weekday suffix (_0 … _6) to get the base ID.
      // Only strip a single digit 0-6, so 'backend_42_3' → 'backend_42'
      // without accidentally stripping the schedule ID from 'backend_42'.
      String baseId = ev.id.replaceAll(RegExp(r'_[0-6]$'), '');

      // Remove all copies of this event from every weekday slot.
      petMap.forEach((weekday, list) {
        list.removeWhere((existingEvent) {
          final existingBase = existingEvent.id.replaceAll(RegExp(r'_[0-6]$'), '');
          return existingBase == baseId;
        });
      });

      // 3. Re-insert the updated event
      if (ev.repeatDaily) {
        // If daily, insert into all 7 days (0-6)
        for (int d = 0; d < 7; d++) {
          petMap.putIfAbsent(d, () => []).add(
            ev.copyWith(id: '${baseId}_$d')
          );
        }
      } else {
        // If weekly, only insert into the current weekday
        final weekday = _weekdayFromKey(dayKey);
        petMap.putIfAbsent(weekday, () => []).add(ev.copyWith(id: baseId));
      }
    });

    // 4. Persist changes to local storage
    _saveToLocal();
  }

  void _deleteEvent(int petId, String dayKey, String eventId) {
    setState(() {
      String baseId = eventId.replaceAll(RegExp(r'_[0-6]$'), '');
      _recurring[petId]?.forEach((_, list) {
        list.removeWhere((e) {
          final existingBase = e.id.replaceAll(RegExp(r'_[0-6]$'), '');
          return existingBase == baseId;
        });
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

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
  
  // We flatten the map for easier storage
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
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Feeding Schedule',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
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
          // ── Gradient background (matching ReportHistoryPage) ──
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
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Week nav bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                weekLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            _NavButton(
                                label: '‹', onTap: () => _shiftWeek(-1)),
                            const SizedBox(width: 6),
                            _NavButton(
                                label: 'This Week', onTap: () => _shiftWeek(0)),
                            const SizedBox(width: 6),
                            _NavButton(
                                label: '›', onTap: () => _shiftWeek(1)),
                          ],
                        ),
                      ),

                      // Pet tabs
                      if (_pets.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: SingleChildScrollView(
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
                                    onTap: () => setState(
                                        () => _activePetId = p.id),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 180),
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? petColor
                                            : petColor.withValues(alpha: 0.25),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: active
                                              ? petColor
                                              : petColor.withValues(alpha: 0.5),
                                          width: active ? 2 : 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        p.species.isNotEmpty
                                            ? '${p.name} (${p.species})'
                                            : p.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
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
                        padding:
                            const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Row(
                          children: EventType.values
                              .map(
                                (t) => Padding(
                                  padding:
                                      const EdgeInsets.only(right: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: t.textColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        t.label,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      // Calendar grid
                      Expanded(
                        child: _activePetId == null
                            ? const Center(
                                child: Text(
                                  'No pets found.\nMake sure your account has pets registered.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 0, 12, 16),
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: MediaQuery.of(context)
                                              .size
                                              .width >
                                          700
                                      ? MediaQuery.of(context)
                                              .size
                                              .width -
                                          24
                                      : 700,
                                  child: _CalendarGrid(
                                    weekStart: ws,
                                    activePetId: _activePetId!,
                                    petColorIndex: _pets.indexWhere((p) => p.id == _activePetId),
                                    eventsForDay: _eventsForDay,
                                    onAddTap: (dayKey) =>
                                        _openEventDialog(dayKey: dayKey),
                                    onEventTap: (ev, dayKey) =>
                                        _openEventDialog(
                                            existing: ev,
                                            dayKey: dayKey),
                                  ),
                                ),
                              ),
                      ),
                    ],
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
                        fontSize: 11,
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
                          fontSize: 14,
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
              _fmt12(event.time),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Icon(t.icon, size: 10, color: Colors.black87),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Button ───────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          border: Border.all(color: Colors.white54, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500),
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
    _repeatDaily = ev?.repeatDaily ?? false;
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
              value: _type,
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
                value: _petId,
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
                    Text(_fmt12(_time),
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

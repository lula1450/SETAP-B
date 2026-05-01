import 'package:flutter/material.dart';
import 'package:maincode/widgets/app_drawer.dart';
import 'package:maincode/services/pet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          title: const Text('Feeding Schedule'),
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
    int? petId,
  }) {
    return PetEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      time: time ?? this.time,
      petId: petId ?? this.petId,
    );
  }
}

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

class _FeedingSchedulePageState extends State<FeedingSchedulePage> {
  final PetService _service = PetService();

  List<Pet> _pets = [];
  int? _activePetId;
  int _weekOffset = 0;
  bool _isLoading = true;

  // events[petId][dateKey] = list of PetEvent
  final Map<int, Map<String, List<PetEvent>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int ownerId = prefs.getInt('owner_id') ?? 0;
      final rawPets = await _service.getOwnerPets(ownerId);

      if (!mounted) return;

      final pets = rawPets.map((j) => Pet.fromJson(j as Map<String, dynamic>)).toList();

      setState(() {
        _pets = pets;
        if (pets.isNotEmpty) {
          _activePetId = pets.first.id;
          for (final p in pets) {
            _events.putIfAbsent(p.id, () => {});
          }
          _seedDefaultsForWeek();
        }
      });
    } catch (e) {
      debugPrint('Error loading pets: $e');
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

  /// Seeds sensible default feeding events for every pet for the current week.
  void _seedDefaultsForWeek() {
    final ws = _weekStart;
    for (final pet in _pets) {
      final petMap = _events[pet.id]!;
      for (int i = 0; i < 7; i++) {
        final d = ws.add(Duration(days: i));
        final k = _dateKey(d);
        petMap.putIfAbsent(k, () => [
          PetEvent(
            id: _uid(),
            type: EventType.feeding,
            name: 'Morning feed',
            time: const TimeOfDay(hour: 7, minute: 30),
            petId: pet.id,
          ),
          PetEvent(
            id: _uid(),
            type: EventType.feeding,
            name: 'Evening feed',
            time: const TimeOfDay(hour: 18, minute: 0),
            petId: pet.id,
          ),
        ]);
      }
    }
  }

  void _shiftWeek(int dir) {
    setState(() {
      _weekOffset = dir == 0 ? 0 : _weekOffset + dir;
      _seedDefaultsForWeek();
    });
  }

  // ── Event CRUD ────────────────────────────────────────────────────────────

  List<PetEvent> _eventsForDay(int petId, String dayKey) {
    final list = List<PetEvent>.from(_events[petId]?[dayKey] ?? []);
    list.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
    return list;
  }

  void _upsertEvent(PetEvent ev, String dayKey) {
    setState(() {
      final petMap = _events[ev.petId] ?? {};
      _events[ev.petId] = petMap;
      final dayList = petMap.putIfAbsent(dayKey, () => []);
      final idx = dayList.indexWhere((e) => e.id == ev.id);
      if (idx >= 0) {
        dayList[idx] = ev;
      } else {
        dayList.add(ev);
      }
    });
  }

  void _deleteEvent(int petId, String dayKey, String eventId) {
    setState(() {
      _events[petId]?[dayKey]?.removeWhere((e) => e.id == eventId);
    });
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
          // Decorative circles — top-left
          Positioned(
            top: -40, left: -100,
            child: _backgroundCircle(350, Colors.white.withValues(alpha: 0.1)),
          ),
          Positioned(
            top: -20, left: -70,
            child: _backgroundCircle(370, Colors.white.withValues(alpha: 0.2)),
          ),
          Positioned(
            top: 10, left: -30,
            child: _backgroundCircle(340, Colors.white.withValues(alpha: 0.3)),
          ),
          // Decorative circles — bottom-right
          Positioned(
            bottom: -40, right: -100,
            child: _backgroundCircle(350, Colors.white.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: -20, right: -70,
            child: _backgroundCircle(370, Colors.white.withValues(alpha: 0.2)),
          ),
          Positioned(
            bottom: 10, right: -30,
            child: _backgroundCircle(340, Colors.white.withValues(alpha: 0.3)),
          ),

          // ── Main content ──
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Week nav bar
                      Container(
                        color: Colors.white.withValues(alpha: 0.25),
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
                                label: 'Today', onTap: () => _shiftWeek(0)),
                            const SizedBox(width: 6),
                            _NavButton(
                                label: '›', onTap: () => _shiftWeek(1)),
                          ],
                        ),
                      ),

                      // Pet tabs
                      if (_pets.isNotEmpty)
                        Container(
                          color: Colors.white.withValues(alpha: 0.2),
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _pets.map((p) {
                                final active = p.id == _activePetId;
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
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.45),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: active
                                              ? const Color(0xFF8BAEAE)
                                              : Colors.white54,
                                          width: active ? 2 : 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        p.species.isNotEmpty
                                            ? '${p.name} (${p.species})'
                                            : p.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: active
                                              ? const Color(0xFF8BAEAE)
                                              : Colors.black54,
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

  Widget _backgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 30),
      ),
    );
  }
}

// ─── Calendar Grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime weekStart;
  final int activePetId;
  final List<PetEvent> Function(int petId, String dayKey) eventsForDay;
  final void Function(String dayKey) onAddTap;
  final void Function(PetEvent ev, String dayKey) onEventTap;

  const _CalendarGrid({
    required this.weekStart,
    required this.activePetId,
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
  final VoidCallback onTap;

  const _EventChip({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = event.type;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: t.backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: t.borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fmt12(event.time),
              style: TextStyle(
                fontSize: 10,
                color: t.textColor.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Icon(t.icon, size: 10, color: t.textColor),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    event.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.textColor,
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

  @override
  void initState() {
    super.initState();
    final ev = widget.existing;
    _type = ev?.type ?? EventType.feeding;
    _petId = ev?.petId ?? widget.activePetId;
    _nameCtrl = TextEditingController(text: ev?.name ?? '');
    _time = ev?.time ?? const TimeOfDay(hour: 8, minute: 0);
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
          ],
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(
                foregroundColor: Colors.red[700]),
            child: const Text('Delete'),
          ),
        const Spacer(),
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

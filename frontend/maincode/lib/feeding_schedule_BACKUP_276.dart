import 'package:flutter/material.dart';
import 'package:maincode/widgets/app_drawer.dart';

// Entry point of the app
void main() => runApp(const PetCareApp());

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      home: const FeedingSchedulePage(),
    );
  }
}

// Models and data handling for the feeding schedule page
enum EventType { feeding, vet, other }

extension EventTypeExtension on EventType {
  String get label {
    switch (this) {
      case EventType.feeding:
        return 'Feeding';
      case EventType.vet:
        return 'Vet appointment';
      case EventType.other:
        return 'Other';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EventType.feeding:
        return const Color(0xFFE1F5EE);
      case EventType.vet:
        return const Color(0xFFE6F1FB);
      case EventType.other:
        return const Color(0xFFFAECE7);
    }
  }

  Color get textColor {
    switch (this) {
      case EventType.feeding:
        return const Color(0xFF0F6E56);
      case EventType.vet:
        return const Color(0xFF185FA5);
      case EventType.other:
        return const Color(0xFF993C1D);
    }
  }

  Color get borderColor {
    switch (this) {
      case EventType.feeding:
        return const Color(0xFF5DCAA5);
      case EventType.vet:
        return const Color(0xFF85B7EB);
      case EventType.other:
        return const Color(0xFFF0997B);
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.feeding:
        return Icons.restaurant_rounded;
      case EventType.vet:
        return Icons.local_hospital_rounded;
      case EventType.other:
        return Icons.event_note_rounded;
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
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      time: time ?? this.time,
      petId: petId ?? this.petId,
    );
  }
}

// Helper to generate unique IDs for events
String _uid() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmt12(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final min = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'am' : 'pm';
  return '$hour:$min $period';
}

// Main page for feeding schedule
class FeedingSchedulePage extends StatefulWidget {
  const FeedingSchedulePage({super.key});

  @override
  State<FeedingSchedulePage> createState() => _FeedingSchedulePageState();
}

class _FeedingSchedulePageState extends State<FeedingSchedulePage> {
  static const List<Pet> _pets = [
    Pet(id: 'bentley', name: 'bentley', species: 'Dog'),
    Pet(id: 'Maisie', name: 'Maisie', species: 'Cat'),
  ];

  String _activePetId = 'bentley';
  int _weekOffset = 0;

  // events[petId][dateKey] = list of events
  final Map<String, Map<String, List<PetEvent>>> _events = {
    'bentley': {},
    'Maisie': {},
  };

  @override
  void initState() {
    super.initState();
    _seedDefaults();
  }

  DateTime get _weekStart {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final clean = DateTime(monday.year, monday.month, monday.day);
    return clean.add(Duration(days: _weekOffset * 7));
  }

  void _seedDefaults() {
    final ws = _weekStart;
    for (int i = 0; i < 7; i++) {
      final d = ws.add(Duration(days: i));
      final k = _dateKey(d);

      _events['bentley']!.putIfAbsent(
        k,
        () => [
          PetEvent(
            id: _uid(),
            type: EventType.feeding,
            name: 'Morning feed',
            time: const TimeOfDay(hour: 7, minute: 30),
            petId: 'bentley',
          ),
          PetEvent(
            id: _uid(),
            type: EventType.feeding,
            name: 'Evening feed',
            time: const TimeOfDay(hour: 18, minute: 0),
            petId: 'bentley',
          ),
          if (i == 2)
            PetEvent(
              id: _uid(),
              type: EventType.vet,
              name: 'Checkup',
              time: const TimeOfDay(hour: 10, minute: 0),
              petId: 'bentley',
            ),
        ],
      );

      _events['Maisie']!.putIfAbsent(
        k,
        () => [
          PetEvent(
            id: _uid(),
            type: EventType.feeding,
            name: 'Breakfast',
            time: const TimeOfDay(hour: 8, minute: 0),
            petId: 'Maisie',
          ),
          PetEvent(
            id: _uid(),
            type: EventType.feeding,
            name: 'Dinner',
            time: const TimeOfDay(hour: 17, minute: 30),
            petId: 'Maisie',
          ),
        ],
      );
    }
  }

  void _shiftWeek(int dir) {
    setState(() {
      _weekOffset = dir == 0 ? 0 : _weekOffset + dir;
      _seedDefaults();
    });
  }

  List<PetEvent> _eventsForDay(String petId, String dayKey) {
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
      final petMap = _events[ev.petId]!;
      final dayList = petMap.putIfAbsent(dayKey, () => []);
      final idx = dayList.indexWhere((e) => e.id == ev.id);
      if (idx >= 0) {
        dayList[idx] = ev;
      } else {
        dayList.add(ev);
      }
    });
  }

  void _deleteEvent(String petId, String dayKey, String eventId) {
    setState(() {
      _events[petId]?[dayKey]?.removeWhere((e) => e.id == eventId);
    });
  }

  Future<void> _openEventDialog({
    PetEvent? existing,
    required String dayKey,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => _EventDialog(
        pets: _pets,
        existing: existing,
        dayKey: dayKey,
        onSave: (ev) => _upsertEvent(ev, dayKey),
        onDelete: existing == null
            ? null
            : () => _deleteEvent(existing.petId, dayKey, existing.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ws = _weekStart;
    final we = ws.add(const Duration(days: 6));
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekLabel =
        '${months[ws.month - 1]} ${ws.day} – ${months[we.month - 1]} ${we.day}, ${we.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Schedule',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE0E0E0)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Week nav bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    weekLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                _NavButton(label: '‹', onTap: () => _shiftWeek(-1)),
                const SizedBox(width: 6),
                _NavButton(label: 'Today', onTap: () => _shiftWeek(0)),
                const SizedBox(width: 6),
                _NavButton(label: '›', onTap: () => _shiftWeek(1)),
              ],
            ),
          ),

          // ── Pet tabs ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: _pets.map((p) {
                final active = p.id == _activePetId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activePetId = p.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF1D9E75)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFFCCCCCC),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '${p.name} (${p.species})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? Colors.white
                              : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Legend ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: EventType.values
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 14),
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
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // ── Calendar grid ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width > 700
                    ? MediaQuery.of(context).size.width - 24
                    : 700,
                child: _CalendarGrid(
                  weekStart: ws,
                  activePetId: _activePetId,
                  eventsForDay: _eventsForDay,
                  onAddTap: (dayKey) => _openEventDialog(dayKey: dayKey),
                  onEventTap: (ev, dayKey) =>
                      _openEventDialog(existing: ev, dayKey: dayKey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Calender grid showing days of the week and events for the active pet
class _CalendarGrid extends StatelessWidget {
  final DateTime weekStart;
  final String activePetId;
  final List<PetEvent> Function(String petId, String dayKey) eventsForDay;
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
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF1D9E75)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 0.5, color: const Color(0xFFE0E0E0)),
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
                      border: Border.all(
                        color: const Color(0xFFCCCCCC),
                        width: 0.5,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFFAAAAAA),
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

// Event chip widget showing event name and time, colored by event type
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
            Text(
              event.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: t.textColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// Navigation button used in the week nav bar
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
          border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
        ),
      ),
    );
  }
}

// ─── Event Dialog ─────────────────────────────────────────────────────────────
class _EventDialog extends StatefulWidget {
  final List<Pet> pets;
  final PetEvent? existing;
  final String dayKey;
  final void Function(PetEvent ev) onSave;
  final VoidCallback? onDelete;

  const _EventDialog({
    required this.pets,
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
  late String _petId;
  late TextEditingController _nameCtrl;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final ev = widget.existing;
    _type = ev?.type ?? EventType.feeding;
    _petId = ev?.petId ?? widget.pets.first.id;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        widget.existing == null ? 'Add event' : 'Edit event',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type
            _Label('Type'),
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
                          Text(t.label, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),

            // Pet
            _Label('Pet'),
            DropdownButtonFormField<String>(
              value: _petId,
              decoration: _inputDeco(),
              items: widget.pets
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.name} (${p.species})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _petId = v!),
            ),
            const SizedBox(height: 12),

            // Name
            _Label('Name / label'),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDeco().copyWith(hintText: 'e.g. Morning feed'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Time
            _Label('Time'),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFCCCCCC),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF888888),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmt12(_time), style: const TextStyle(fontSize: 14)),
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
              foregroundColor: const Color(0xFF993C1D),
            ),
            child: const Text('Delete'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF666666)),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D9E75),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  InputDecoration _inputDeco() => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
    ),
  );
}

// Small label widget used in the event dialog
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

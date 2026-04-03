import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maincode/edit_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _MedicationRecord {
  String title;
  String subtitle;
  String status;
  Color statusColor;

  _MedicationRecord({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
  });

  static const _statusColorMap = {
    'Active': 0xFF34C759,
    'Completed': 0xFF8E8E93,
    'On Hold': 0xFFFF9500,
  };

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'status': status,
  };

  factory _MedicationRecord.fromJson(Map<String, dynamic> j) =>
      _MedicationRecord(
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        status: j['status'] as String,
        statusColor: Color(_statusColorMap[j['status']] ?? 0xFF8E8E93),
      );
}

class _AllergyRecord {
  String title;
  String subtitle;
  String severity;
  Color severityColor;

  _AllergyRecord({
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.severityColor,
  });

  static const _severityColorMap = {
    'High Risk': 0xFFE8472A,
    'Moderate': 0xFFFF9500,
    'Low': 0xFF34C759,
  };

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'severity': severity,
  };

  factory _AllergyRecord.fromJson(Map<String, dynamic> j) => _AllergyRecord(
    title: j['title'] as String,
    subtitle: j['subtitle'] as String,
    severity: j['severity'] as String,
    severityColor: Color(_severityColorMap[j['severity']] ?? 0xFFFF9500),
  );
}

class _ConditionRecord {
  String title;
  String subtitle;
  String status;
  Color statusColor;

  _ConditionRecord({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
  });

  static const _statusColorMap = {
    'Ongoing': 0xFFFF9500,
    'Chronic': 0xFF4A90D9,
    'Resolved': 0xFF8E8E93,
  };

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'status': status,
  };

  factory _ConditionRecord.fromJson(Map<String, dynamic> j) => _ConditionRecord(
    title: j['title'] as String,
    subtitle: j['subtitle'] as String,
    status: j['status'] as String,
    statusColor: Color(_statusColorMap[j['status']] ?? 0xFF8E8E93),
  );
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class HealthRecordsPage extends StatefulWidget {
  /// Pass a unique identifier for the current pet so records are stored
  /// separately per pet profile. Defaults to 'default' if not provided.
  final String petId;

  const HealthRecordsPage({super.key, this.petId = 'default'});

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage> {
  // Start empty — all data comes from SharedPreferences
  List<_MedicationRecord> _medications = [];
  List<_AllergyRecord> _allergies = [];
  List<_ConditionRecord> _conditions = [];

  bool _isLoading = true;

  // SharedPreferences keys scoped to this pet
  String get _medKey => 'health_medications_${widget.petId}';
  String get _allergyKey => 'health_allergies_${widget.petId}';
  String get _conditionKey => 'health_conditions_${widget.petId}';

  // ---------------------------------------------------------------------------
  // Persistence helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final medJson = prefs.getString(_medKey);
    final allergyJson = prefs.getString(_allergyKey);
    final conditionJson = prefs.getString(_conditionKey);

    setState(() {
      if (medJson != null) {
        final list = jsonDecode(medJson) as List<dynamic>;
        _medications = list
            .map((e) => _MedicationRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (allergyJson != null) {
        final list = jsonDecode(allergyJson) as List<dynamic>;
        _allergies = list
            .map((e) => _AllergyRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (conditionJson != null) {
        final list = jsonDecode(conditionJson) as List<dynamic>;
        _conditions = list
            .map((e) => _ConditionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _isLoading = false;
    });
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _medKey,
      jsonEncode(_medications.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _allergyKey,
      jsonEncode(_allergies.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveConditions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _conditionKey,
      jsonEncode(_conditions.map((e) => e.toJson()).toList()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------------------------------------------------------------------
  // Add dialogs
  // ---------------------------------------------------------------------------

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedStatus = 'Active';
    final statusOptions = ['Active', 'Completed', 'On Hold'];
    final Map<String, Color> statusColors = {
      'Active': const Color(0xFF34C759),
      'Completed': const Color(0xFF8E8E93),
      'On Hold': const Color(0xFFFF9500),
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Medication',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: _inputDecoration(
                  'Medication name & dose',
                  Icons.medication_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleController,
                decoration: _inputDecoration(
                  'Frequency · Reason',
                  Icons.info_outline,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: _inputDecoration('Status', Icons.circle_outlined),
                items: statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90D9),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                setState(() {
                  _medications.add(
                    _MedicationRecord(
                      title: nameController.text.trim(),
                      subtitle: subtitleController.text.trim().isEmpty
                          ? 'No details provided'
                          : subtitleController.text.trim(),
                      status: selectedStatus,
                      statusColor: statusColors[selectedStatus]!,
                    ),
                  );
                });
                _saveMedications();
                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAllergyDialog() {
    final nameController = TextEditingController();
    final reactionController = TextEditingController();
    String selectedSeverity = 'Moderate';
    final severityOptions = ['Low', 'Moderate', 'High Risk'];
    final Map<String, Color> severityColors = {
      'Low': const Color(0xFF34C759),
      'Moderate': const Color(0xFFFF9500),
      'High Risk': const Color(0xFFE8472A),
    };
    final Map<String, String> severityLabels = {
      'Low': 'Mild',
      'Moderate': 'Moderate',
      'High Risk': 'Severe',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Allergy',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: _inputDecoration(
                  'Allergen name',
                  Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reactionController,
                decoration: _inputDecoration(
                  'Reaction (e.g. Hives, swelling)',
                  Icons.info_outline,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedSeverity,
                decoration: _inputDecoration('Severity', Icons.circle_outlined),
                items: severityOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedSeverity = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8472A),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                final reaction = reactionController.text.trim().isEmpty
                    ? 'No reaction details'
                    : reactionController.text.trim();
                setState(() {
                  _allergies.add(
                    _AllergyRecord(
                      title: nameController.text.trim(),
                      subtitle:
                          '${severityLabels[selectedSeverity]} · $reaction',
                      severity: selectedSeverity,
                      severityColor: severityColors[selectedSeverity]!,
                    ),
                  );
                });
                _saveAllergies();
                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddConditionDialog() {
    final nameController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedStatus = 'Ongoing';
    final statusOptions = ['Ongoing', 'Chronic', 'Resolved'];
    final Map<String, Color> statusColors = {
      'Ongoing': const Color(0xFFFF9500),
      'Chronic': const Color(0xFF4A90D9),
      'Resolved': const Color(0xFF8E8E93),
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Injury / Condition',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: _inputDecoration(
                  'Injury or condition name',
                  Icons.healing_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleController,
                decoration: _inputDecoration(
                  'Date / notes (e.g. Jan 2024 · Managed)',
                  Icons.info_outline,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: _inputDecoration('Status', Icons.circle_outlined),
                items: statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B59B6),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                setState(() {
                  _conditions.add(
                    _ConditionRecord(
                      title: nameController.text.trim(),
                      subtitle: subtitleController.text.trim().isEmpty
                          ? 'No details provided'
                          : subtitleController.text.trim(),
                      status: selectedStatus,
                      statusColor: statusColors[selectedStatus]!,
                    ),
                  );
                });
                _saveConditions();
                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Remove confirm
  // ---------------------------------------------------------------------------

  void _confirmRemove(String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Record'),
        content: Text('Remove "$itemName" from health records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildDrawer() {
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
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _drawerTile(
            Icons.person,
            'Edit Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),
          _drawerTile(Icons.notifications, 'Notifications'),
          _drawerTile(Icons.palette, 'Report History'),
          _drawerTile(Icons.logout, 'Logout'),
          _drawerTile(
            Icons.delete_forever,
            'Delete Account',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("Permanently delete profile and pet data?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      endDrawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text(
          'Health Records',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE8ECF0), height: 1),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Medications
                _buildSectionCard(
                  title: 'Medications',
                  icon: Icons.medication_rounded,
                  accentColor: const Color(0xFF4A90D9),
                  backgroundColor: const Color(0xFFEBF4FF),
                  emptyLabel: 'No medications recorded',
                  emptyIcon: Icons.medication_rounded,
                  itemCount: _medications.length,
                  onAdd: _showAddMedicationDialog,
                  itemBuilder: (index) {
                    final med = _medications[index];
                    return _RecordItemWidget(
                      title: med.title,
                      subtitle: med.subtitle,
                      trailing: med.status,
                      trailingColor: med.statusColor,
                      onRemove: () => _confirmRemove(med.title, () {
                        setState(() => _medications.removeAt(index));
                        _saveMedications();
                      }),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Allergies
                _buildSectionCard(
                  title: 'Allergies',
                  icon: Icons.warning_amber_rounded,
                  accentColor: const Color(0xFFE8472A),
                  backgroundColor: const Color(0xFFFFF0EE),
                  emptyLabel: 'No allergies recorded',
                  emptyIcon: Icons.warning_amber_rounded,
                  itemCount: _allergies.length,
                  onAdd: _showAddAllergyDialog,
                  itemBuilder: (index) {
                    final allergy = _allergies[index];
                    return _RecordItemWidget(
                      title: allergy.title,
                      subtitle: allergy.subtitle,
                      trailing: allergy.severity,
                      trailingColor: allergy.severityColor,
                      onRemove: () => _confirmRemove(allergy.title, () {
                        setState(() => _allergies.removeAt(index));
                        _saveAllergies();
                      }),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Injuries & Conditions
                _buildSectionCard(
                  title: 'Injuries & Conditions',
                  icon: Icons.healing_rounded,
                  accentColor: const Color(0xFF9B59B6),
                  backgroundColor: const Color(0xFFF5EEFF),
                  emptyLabel: 'No injuries or conditions recorded',
                  emptyIcon: Icons.healing_rounded,
                  itemCount: _conditions.length,
                  onAdd: _showAddConditionDialog,
                  itemBuilder: (index) {
                    final condition = _conditions[index];
                    return _RecordItemWidget(
                      title: condition.title,
                      subtitle: condition.subtitle,
                      trailing: condition.status,
                      trailingColor: condition.statusColor,
                      onRemove: () => _confirmRemove(condition.title, () {
                        setState(() => _conditions.removeAt(index));
                        _saveConditions();
                      }),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    required String emptyLabel,
    required IconData emptyIcon,
    required int itemCount,
    required VoidCallback onAdd,
    required Widget Function(int index) itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '$itemCount records',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: accentColor, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),

          // Empty state — tappable prompt
          if (itemCount == 0)
            GestureDetector(
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: accentColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tap to add — $emptyLabel yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(itemCount, (index) {
              final isLast = index == itemCount - 1;
              return Column(
                children: [
                  itemBuilder(index),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Container(
                        height: 1,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                ],
              );
            }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// Record item widget

class _RecordItemWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final VoidCallback onRemove;

  const _RecordItemWidget({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: trailingColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trailingColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

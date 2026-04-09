import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:maincode/edit_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

// Data models

class _MedicationRecord {
  String title;
  String subtitle;
  String status;
  Color statusColor;
  DateTime? startDate;

  _MedicationRecord({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.startDate,
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
    'startDate': startDate?.toIso8601String(),
  };

  factory _MedicationRecord.fromJson(Map<String, dynamic> j) =>
      _MedicationRecord(
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        status: j['status'] as String,
        statusColor: Color(_statusColorMap[j['status']] ?? 0xFF8E8E93),
        startDate: j['startDate'] != null
            ? DateTime.tryParse(j['startDate'] as String)
            : null,
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

// Medical Document model

class _MedicalDocument {
  final String label;
  final String category;
  final String filePath;
  final String fileName;
  final DateTime uploadedAt;

  _MedicalDocument({
    required this.label,
    required this.category,
    required this.filePath,
    required this.fileName,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'category': category,
    'filePath': filePath,
    'fileName': fileName,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory _MedicalDocument.fromJson(Map<String, dynamic> j) => _MedicalDocument(
    label: j['label'] as String,
    category: j['category'] as String,
    filePath: j['filePath'] as String,
    fileName: j['fileName'] as String,
    uploadedAt: DateTime.parse(j['uploadedAt'] as String),
  );
}

// Page

class HealthRecordsPage extends StatefulWidget {
  final String petId;

  const HealthRecordsPage({super.key, this.petId = 'default'});

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage> {
  List<_MedicationRecord> _medications = [];
  List<_AllergyRecord> _allergies = [];
  List<_ConditionRecord> _conditions = [];
  List<_MedicalDocument> _documents = [];

  bool _isLoading = true;

  String get _medKey => 'health_medications_${widget.petId}';
  String get _allergyKey => 'health_allergies_${widget.petId}';
  String get _conditionKey => 'health_conditions_${widget.petId}';
  String get _docKey => 'health_documents_${widget.petId}';

  // Persistence

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      final medJson = prefs.getString(_medKey);
      if (medJson != null) {
        _medications = (jsonDecode(medJson) as List<dynamic>)
            .map((e) => _MedicationRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final allergyJson = prefs.getString(_allergyKey);
      if (allergyJson != null) {
        _allergies = (jsonDecode(allergyJson) as List<dynamic>)
            .map((e) => _AllergyRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final conditionJson = prefs.getString(_conditionKey);
      if (conditionJson != null) {
        _conditions = (jsonDecode(conditionJson) as List<dynamic>)
            .map((e) => _ConditionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final docJson = prefs.getString(_docKey);
      if (docJson != null) {
        _documents = (jsonDecode(docJson) as List<dynamic>)
            .map((e) => _MedicalDocument.fromJson(e as Map<String, dynamic>))
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

  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _docKey,
      jsonEncode(_documents.map((e) => e.toJson()).toList()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Document upload flow

  Future<void> _pickAndSaveDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'txt',
        'jpg', 'jpeg', 'png', 'heic',
        'xls', 'xlsx', 'csv',
      ],
      withData: true, // required on web to get bytes
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;

    if (kIsWeb) {
      // On web there is no file system — store metadata only
      if (!mounted) return;
      await _showDocumentMetaDialog('', picked.name);
    } else {
      if (picked.path == null) return;
      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory('${appDir.path}/health_docs/${widget.petId}');
      await destDir.create(recursive: true);
      final destPath =
          '${destDir.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      await File(picked.path!).copy(destPath);
      if (!mounted) return;
      await _showDocumentMetaDialog(destPath, picked.name);
    }
  }

  Future<void> _showDocumentMetaDialog(
    String savedPath,
    String originalName,
  ) async {
    final labelController = TextEditingController(
      text: p.basenameWithoutExtension(originalName),
    );
    String selectedCategory = 'Vet Report';
    const categories = [
      'Vet Report',
      'Prescription',
      'X-Ray / Scan',
      'Blood Test',
      'Vaccination',
      'Other',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Save Document',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: _inputDecoration(
                  'Document label',
                  Icons.label_outline,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: _inputDecoration('Category', Icons.folder_outlined),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedCategory = val!),
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
                backgroundColor: const Color(0xFF2E7D9B),
              ),
              onPressed: () {
                final label = labelController.text.trim().isEmpty
                    ? p.basenameWithoutExtension(originalName)
                    : labelController.text.trim();
                setState(() {
                  _documents.add(
                    _MedicalDocument(
                      label: label,
                      category: selectedCategory,
                      filePath: savedPath,
                      fileName: originalName,
                      uploadedAt: DateTime.now(),
                    ),
                  );
                });
                _saveDocuments();
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openDocument(_MedicalDocument doc) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening files is not supported on web.')),
        );
      }
      return;
    }
    if (doc.filePath.isEmpty) return;
    final file = File(doc.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found — it may have been moved or deleted.'),
          ),
        );
      }
      return;
    }
    await OpenFilex.open(doc.filePath);
  }

  void _confirmRemoveDocument(_MedicalDocument doc, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Document'),
        content: Text('Remove "${doc.label}" from medical documents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              if (!kIsWeb && doc.filePath.isNotEmpty) {
                final file = File(doc.filePath);
                if (await file.exists()) await file.delete();
              }
              setState(() => _documents.removeAt(index));
              _saveDocuments();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Add dialogs — medications

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedStatus = 'Active';
    DateTime? selectedStartDate;
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
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedStartDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    helpText: 'Select start date',
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF4A90D9),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedStartDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFBDBDBD)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: Color(0xFF757575),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedStartDate != null
                            ? _formatDate(selectedStartDate!)
                            : 'Start date (optional)',
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedStartDate != null
                              ? Colors.black87
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                      const Spacer(),
                      if (selectedStartDate != null)
                        GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedStartDate = null),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                    ],
                  ),
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
                      startDate: selectedStartDate,
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

  // Add dialogs — allergies

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

  // Add dialogs — conditions

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

  // Remove confirm

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

  // Helpers

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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

  (IconData, Color) _docIconFor(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return switch (ext) {
      '.pdf' => (Icons.picture_as_pdf_rounded, const Color(0xFFE53935)),
      '.doc' || '.docx' => (Icons.description_rounded, const Color(0xFF1565C0)),
      '.xls' ||
      '.xlsx' ||
      '.csv' => (Icons.table_chart_rounded, const Color(0xFF2E7D32)),
      '.jpg' ||
      '.jpeg' ||
      '.png' ||
      '.heic' => (Icons.image_rounded, const Color(0xFF6A1B9A)),
      '.txt' => (Icons.text_snippet_rounded, const Color(0xFF37474F)),
      _ => (Icons.insert_drive_file_rounded, const Color(0xFF546E7A)),
    };
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
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
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

  // Build

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
                  itemCount: _medications.length,
                  onAdd: _showAddMedicationDialog,
                  itemBuilder: (index) {
                    final med = _medications[index];
                    return _RecordItemWidget(
                      title: med.title,
                      subtitle: med.subtitle,
                      trailing: med.status,
                      trailingColor: med.statusColor,
                      startDate: med.startDate,
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
                const SizedBox(height: 16),

                // Medical Documents
                _buildDocumentsCard(),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  // Documents card

  Widget _buildDocumentsCard() {
    const accentColor = Color(0xFF2E7D9B);
    const backgroundColor = Color(0xFFE8F4F8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  child: const Icon(
                    Icons.folder_copy_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Medical Documents',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_documents.length} ${_documents.length == 1 ? 'file' : 'files'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickAndSaveDocument,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),

          if (_documents.isEmpty)
            GestureDetector(
              onTap: _pickAndSaveDocument,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 36,
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload a document',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vet reports, prescriptions, X-rays, blood tests & more',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PDF · DOC · JPG · PNG · XLS · TXT',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_documents.length, (index) {
              final doc = _documents[index];
              final isLast = index == _documents.length - 1;
              final (icon, iconColor) = _docIconFor(doc.fileName);

              return Column(
                children: [
                  InkWell(
                    onTap: () => _openDocument(doc),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: iconColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doc.fileName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        doc.category,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 10,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatDate(doc.uploadedAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[400],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _confirmRemoveDocument(doc, index),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Container(height: 1, color: const Color(0xFFF5F5F5)),
                    ),
                ],
              );
            }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Generic section card

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    required String emptyLabel,
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: accentColor, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),

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
                      color: accentColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tap to add — $emptyLabel yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor.withValues(alpha: 0.8),
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
                      child: Container(height: 1, color: const Color(0xFFF5F5F5)),
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
  final DateTime? startDate;

  const _RecordItemWidget({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.onRemove,
    this.startDate,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
                if (startDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Started ${_formatDate(startDate!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: trailingColor.withValues(alpha: 0.12),
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
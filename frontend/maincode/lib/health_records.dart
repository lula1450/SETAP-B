import 'package:flutter/material.dart';

class HealthRecordsPage extends StatelessWidget {
  const HealthRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
      ),
      body: Column(
        children: [
          // Top action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _AddButton(
                    label: 'Medication',
                    icon: Icons.add,
                    color: const Color.fromARGB(255, 91, 247, 146),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AddButton(
                    label: 'Allergy',
                    icon: Icons.add,
                    color: const Color.fromARGB(255, 255, 251, 21),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AddButton(
                    label: 'Injury',
                    icon: Icons.add,
                    color: const Color.fromARGB(255, 254, 56, 79),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),

          // Existing content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _SectionCard(
                  title: 'Medications',
                  icon: Icons.medication_rounded,
                  accentColor: Color(0xFF4A90D9),
                  backgroundColor: Color(0xFFEBF4FF),
                  items: [
                    _RecordItem(
                      title: 'Lisinopril 10mg',
                      subtitle: 'Once daily · Blood pressure',
                      trailing: 'Active',
                      trailingColor: Color(0xFF34C759),
                    ),
                    _RecordItem(
                      title: 'Metformin 500mg',
                      subtitle: 'Twice daily · Diabetes management',
                      trailing: 'Active',
                      trailingColor: Color(0xFF34C759),
                    ),
                    _RecordItem(
                      title: 'Atorvastatin 20mg',
                      subtitle: 'Once daily at bedtime · Cholesterol',
                      trailing: 'Active',
                      trailingColor: Color(0xFF34C759),
                    ),
                    _RecordItem(
                      title: 'Amoxicillin 500mg',
                      subtitle: 'Three times daily · Infection',
                      trailing: 'Completed',
                      trailingColor: Color(0xFF8E8E93),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _SectionCard(
                  title: 'Allergies',
                  icon: Icons.warning_amber_rounded,
                  accentColor: Color(0xFFE8472A),
                  backgroundColor: Color(0xFFFFF0EE),
                  items: [
                    _RecordItem(
                      title: 'Penicillin',
                      subtitle: 'Severe · Anaphylaxis',
                      trailing: 'High Risk',
                      trailingColor: Color(0xFFE8472A),
                    ),
                    _RecordItem(
                      title: 'Shellfish',
                      subtitle: 'Moderate · Hives, swelling',
                      trailing: 'Moderate',
                      trailingColor: Color(0xFFFF9500),
                    ),
                    _RecordItem(
                      title: 'Latex',
                      subtitle: 'Mild · Contact dermatitis',
                      trailing: 'Low',
                      trailingColor: Color(0xFF34C759),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _SectionCard(
                  title: 'Injuries & Conditions',
                  icon: Icons.healing_rounded,
                  accentColor: Color(0xFF9B59B6),
                  backgroundColor: Color(0xFFF5EEFF),
                  items: [
                    _RecordItem(
                      title: 'Fractured Left Wrist',
                      subtitle: 'March 2022 · Healed',
                      trailing: 'Resolved',
                      trailingColor: Color(0xFF8E8E93),
                    ),
                    _RecordItem(
                      title: 'Lower Back Strain',
                      subtitle: 'Ongoing · Physiotherapy',
                      trailing: 'Ongoing',
                      trailingColor: Color(0xFFFF9500),
                    ),
                    _RecordItem(
                      title: 'Type 2 Diabetes',
                      subtitle: 'Diagnosed Jan 2020 · Managed',
                      trailing: 'Chronic',
                      trailingColor: Color(0xFF4A90D9),
                    ),
                    _RecordItem(
                      title: 'Hypertension',
                      subtitle: 'Diagnosed May 2019 · Controlled',
                      trailing: 'Chronic',
                      trailingColor: Color(0xFF4A90D9),
                    ),
                  ],
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AddButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final List<_RecordItem> items;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                  '${items.length} records',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                entry.value,
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

class _RecordItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;

  const _RecordItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}
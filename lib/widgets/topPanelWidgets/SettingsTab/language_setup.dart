import 'package:flutter/material.dart';

class LanguageSettingsDialog extends StatefulWidget {
  @override
  _LanguageSettingsDialogState createState() => _LanguageSettingsDialogState();
}

class _LanguageSettingsDialogState extends State<LanguageSettingsDialog> {
  static const Color _primaryColor = Color(0xFF521C1D);
  final List<Map<String, String>> data = [
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
    {"English": "Chicken Biryani", "Arabic": "برياني الدجاج"},
    {"English": "Veg Biryani", "Arabic": "برياني الخضار"},
    {"English": "Pasta", "Arabic": "المعكرونة"},
  ];

 @override
Widget build(BuildContext context) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Container(
      width: 600,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildTableSection(),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    ),
  );
}
Widget _buildHeader(BuildContext context) {
  return Container(
    constraints: const BoxConstraints(minHeight: 56),
    padding: const EdgeInsets.only(left: 20, right: 8),
    decoration: const BoxDecoration(
      color: _primaryColor,
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Language Settings',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            tooltip: 'Close',
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _buildTableSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Column headers (fixed)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'English Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Arabic Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
      // Scrollable rows
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.grey[300]!),
              right: BorderSide(color: Colors.grey[300]!),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return Container(
                constraints: const BoxConstraints(minHeight: 44),
                color: index % 2 == 0 ? Colors.grey[100] : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        data[index]['English']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                                       Expanded(
                      child: Text(
                        data[index]['Arabic']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}

Widget _buildActionButtons(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Save Logic
          },
          icon: const Icon(Icons.save, color: Colors.white, size: 20),
          label: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ],
    ),
  );
}
}
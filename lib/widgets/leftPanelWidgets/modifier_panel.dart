import 'package:flutter/material.dart';

class ModifierSelectionDialog extends StatefulWidget {
  final List<String> initialSelectedModifiers;

  const ModifierSelectionDialog(
      {super.key, required this.initialSelectedModifiers});

  @override
  State<ModifierSelectionDialog> createState() =>
      _ModifierSelectionDialogState();
}

class _ModifierSelectionDialogState extends State<ModifierSelectionDialog> {
  final TextEditingController _customController = TextEditingController();

  List<Map<String, dynamic>> modifiers = [];
  Set<String> selectedModifiers = {};
  bool isLoading = true;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addCustomModifier() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      selectedModifiers.add(text);
      _customController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    selectedModifiers = widget.initialSelectedModifiers.toSet();
    _fetchModifiers();
  }

  Future<void> _fetchModifiers() async {
    try {
      final result = <dynamic>[];

      // Ensure it's a List<Map<String, dynamic>>
      final List<Map<String, dynamic>> parsed =
          List<Map<String, dynamic>>.from(result);

      print("🟢 Modifiers fetched:");
      for (var item in parsed) {
        print(item);
      }

      setState(() {
        modifiers = parsed;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching modifiers: $e');
      setState(() {
        modifiers = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔲 Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Modifiers',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => selectedModifiers.clear()),
                  child:
                      const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Divider(),

            // 🔁 Loading or modifiers
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...modifiers.map((mod) {
                    final label = mod['Modifier'] ?? '';
                    final isSelected = selectedModifiers.contains(label);

                    return ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 13)),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          isSelected
                              ? selectedModifiers.remove(label)
                              : selectedModifiers.add(label);
                        });
                      },
                      selectedColor: Colors.blue.shade100,
                      backgroundColor: Colors.grey.shade200,
                    );
                  }),
                  // Show custom modifiers as chips (removable)
                  ...selectedModifiers.where((l) {
                    return !modifiers.any((m) => (m['Modifier'] ?? '') == l);
                  }).map((label) {
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Icon(Icons.close, size: 14, color: Colors.grey.shade700),
                        ],
                      ),
                      selected: true,
                      onSelected: (_) {
                        setState(() => selectedModifiers.remove(label));
                      },
                      selectedColor: Colors.orange.shade100,
                      backgroundColor: Colors.orange.shade50,
                    );
                  }),
                ],
              ),

            const SizedBox(height: 16),

            // Custom modifier input
            Row(
              children: [
                const Text('Custom:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _customController,
                    decoration: const InputDecoration(
                      hintText: 'Type custom modifier...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => _addCustomModifier(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCustomModifier,
                  icon: const Icon(Icons.add_circle),
                  tooltip: 'Add custom modifier',
                  color: const Color(0xFF521C1D),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ✅ Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selectedModifiers.toList());
                  },
                  child: const Text('OK'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

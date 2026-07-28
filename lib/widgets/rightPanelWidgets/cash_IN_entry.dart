import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CashInEntryDialog extends StatefulWidget {
  @override
  _CashInEntryDialogState createState() => _CashInEntryDialogState();
}

class _CashInEntryDialogState extends State<CashInEntryDialog> {
  List<String> descriptions = [];
  bool isLoading = true;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _descFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  bool isKeyboardEnter = false; // to track Enter from keyboard

  bool _showDescriptions = true;
  List<Map<String, String>> entries = [];

  final TextEditingController _typeDescController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchDescriptions();
  }

  Future<void> fetchDescriptions() async {
    try {
      final result = <String>[];
      debugPrint("Fetched Descriptions: $result");
      setState(() {
        descriptions = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching descriptions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleEnterLogic() {
    final desc = _typeDescController.text.trim();
    final amount = _amountController.text.trim();

    if (desc.isEmpty || amount.isEmpty) return;

    setState(() {
      entries.add({
        'description': desc,
        'amount': amount,
      });
      _typeDescController.clear();
      _amountController.clear();
    });

    // Delayed focus ensures previous focus is released first
    Future.delayed(Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_descFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _handleEnterLogic(); // ✅ handles add and refocus
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 950,
          height: 750,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildTypeDescriptionRow(),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 4, child: _buildAccountTableWithTotal()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildItemSearchAndList()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildNumberPad(context)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFooterButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Cash In Entry',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D), // Your dark red
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTypeDescriptionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type Description:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _typeDescController,
                focusNode: _descFocusNode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) {
                  // When user presses Enter, move focus to amount
                  FocusScope.of(context).requestFocus(_amountFocusNode);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 35),
          child: ElevatedButton(
            onPressed: () {
              // Handle "Cash" button click
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF521C1D),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cash',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTableWithTotal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accounts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Account Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'CashOut Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      entry['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF521C1D),
                      ),
                    ),
                    trailing: Text(
                      entry['amount'] ?? '0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0069A1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              entries
                  .fold<double>(
                    0.0,
                    (sum, item) =>
                        sum + double.tryParse(item['amount'] ?? '0')!,
                  )
                  .toStringAsFixed(2),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemSearchAndList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : _showDescriptions
                  ? ListView.separated(
                      itemCount: descriptions.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade300,
                        thickness: 1.5,
                      ),
                      itemBuilder: (context, index) {
                        final desc = descriptions[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _typeDescController.text = desc;
                              _showDescriptions = false;
                            });

                            FocusScope.of(context)
                                .requestFocus(_amountFocusNode);
                            _keyboardFocusNode
                                .requestFocus(); // 👈 ADD THIS LINE
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.description,
                                    color: Color(0xFF521C1D), size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'Selected: ${_typeDescController.text}',
                        style: TextStyle(
                          fontSize: 18, // Increase the font size
                          fontWeight: FontWeight.bold, // Make the text bold
                          color: Colors.black,
                        ),
                      ),
                    ),
        )
      ],
    );
  }

  Widget _buildNumberPad(BuildContext context) {
    final labels = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '0', '.', 'C'];

    return Column(
      children: [
        TextField(
          controller: _amountController,
          focusNode: _amountFocusNode,
          readOnly: false,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 24, color: Colors.black),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: '0',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            itemCount: labels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    String label = labels[index];
                    if (label == 'C') {
                      _amountController.text = '';
                    } else if (label == '.' &&
                        _amountController.text.contains('.')) {
                      // Prevent multiple decimals
                      return;
                    } else {
                      _amountController.text += label;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Color(0xFF521C1D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: Color(0xFF521C1D),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            final desc = _typeDescController.text.trim();
            final amount = _amountController.text.trim();

            if (desc.isEmpty || amount.isEmpty) return;

            setState(() {
              entries.add({
                'description': desc,
                'amount': amount,
              });
              _typeDescController.clear();
              _amountController.clear();
            });

            FocusScope.of(context)
                .requestFocus(_descFocusNode); // 👈 Focus back to desc
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF521C1D),
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: Size(double.infinity, 50),
          ),
          child: Text(
            'Enter',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            // Handle keyboard opening
          },
          icon: Icon(Icons.keyboard, color: Colors.grey),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                if (entries.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Please enter at least one record.")),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Cash IN saved in mock mode (${entries.length} record${entries.length == 1 ? '' : 's'}).'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0069A1),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF521C1D), // Your dark red
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}

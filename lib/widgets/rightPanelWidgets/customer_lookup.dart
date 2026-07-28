import 'package:flutter/material.dart';

class CustomerLookupDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 950, // Adjust width as necessary
        height: 600, // Adjust height as necessary
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFF1F5F9), // Light background
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Section
            Text(
              "Customer Lookup",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF521C1D), // Dark red
              ),
            ),
            const SizedBox(height: 10),

            // Main Content
            Expanded(
              child: Row(
                children: [
                  // Left Section: Customer Details
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle("Last Bills"),
                        _buildTableView([
                          "BillDate",
                          "BillNo",
                          "Bill Amount",
                          "BillOsBalance"
                        ]),
                        const SizedBox(height: 10),
                        _buildSectionTitle("Last Transactions"),
                        _buildTableView(
                            ["Trns.Date", "TransactionType", "Trans.Amount"]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right Section: Customer List
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle("Customer List"),
                        _buildCustomerList(),
                        const SizedBox(height: 16),
                        _buildCustomerInput("Customer Code"),
                        const SizedBox(height: 8),
                        _buildCustomerInput("Customer Name"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer Section: Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton("Print Outstanding"),
                const SizedBox(width: 5),
                _buildActionButton("Receipt Summary"),
                const SizedBox(width: 5),
                _buildActionButton("Receipt Details"),
                const Spacer(),
                _buildFooterButton("Select", const Color(0xFF4CAF50)), // Green
                const SizedBox(width: 5),
                _buildFooterButton("Clear", const Color(0xFFFFC107)), // Orange
                const SizedBox(width: 5),
                _buildFooterButton(
                    "Close", const Color(0xFF521C1D)), // Dark red
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF521C1D), // Dark red
      ),
    );
  }

  // Customer List Widget
  Widget _buildCustomerList() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF521C1D)), // Dark red
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          itemCount: 10, // Replace with actual data count
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                "Customer Name $index",
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                "Customer Code $index",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  // Table View
  Widget _buildTableView(List<String> headers) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF521C1D)), // Dark red
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFF521C1D), // Dark red
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: headers
                    .map((header) => Expanded(
                          child: Text(
                            header,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const Divider(height: 1, color: Colors.black),
            // Table Content Placeholder
            Expanded(
              child: Center(
                child: Text(
                  "No Data Available",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Customer Input Fields
  Widget _buildCustomerInput(String label) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D), // Dark red
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF521C1D)), // Dark red
              borderRadius: BorderRadius.circular(8),
            ),
            child: const TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Action Buttons
  Widget _buildActionButton(String text) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: const Color(0xFF521C1D), // Dark red
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text),
    );
  }

  // Footer Buttons
  Widget _buildFooterButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

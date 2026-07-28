import 'package:flutter/material.dart';

class DayCloseReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400, // Adjust width based on your requirements
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white, // White background as requested
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateField('Report Date From :'),
            const SizedBox(height: 20),
            _buildDateField('Report Date To :'),
            const SizedBox(height: 30),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D), // Dark red color for label
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFF521C1D), width: 1.5),
          ),
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF521C1D)),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              hintText: 'MM-DD-YYYY',
              hintStyle: TextStyle(color: Colors.grey.shade600),
            ),
            onTap: () {
              // Implement date picker logic here
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            // Handle Print action
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Color(0xFF521C1D), backgroundColor: Colors.white,
            side: BorderSide(color: Color(0xFF521C1D)), // Dark red border
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Print',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D), // Dark red text color
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF521C1D),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Close',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

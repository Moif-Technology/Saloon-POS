import 'package:flutter/material.dart';

class ResizableTable extends StatefulWidget {
  final List<String> headers;
  final List<List<dynamic>>
      data; // Dynamic data, including Widgets like CheckBox
  final List<double>? columnWidths;
  final double defaultColumnWidth;
  final double rowHeight;
  final Function(int rowIndex, int colIndex, bool? value)? onCheckboxChanged;

  const ResizableTable({
    Key? key,
    required this.headers,
    required this.data,
    this.columnWidths,
    this.defaultColumnWidth = 150,
    this.rowHeight = 40,
    this.onCheckboxChanged,
  }) : super(key: key);

  @override
  _ResizableTableState createState() => _ResizableTableState();
}

class _ResizableTableState extends State<ResizableTable> {
  late List<double> columnWidths;

  @override
  void initState() {
    super.initState();
    // Initialize column widths
    columnWidths = widget.columnWidths ??
        List.filled(widget.headers.length, widget.defaultColumnWidth);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Table Header
          Row(
            children: List.generate(widget.headers.length, (index) {
              return _buildResizableColumnHeader(index, widget.headers[index]);
            }),
          ),
          // Table Data Rows
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: List.generate(widget.data.length, (rowIndex) {
                  return Row(
                    children: List.generate(widget.headers.length, (colIndex) {
                      final cellData = widget.data[rowIndex][colIndex];
                      return Container(
                        width: columnWidths[colIndex],
                        height: widget.rowHeight,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                        ),
                        child: cellData is Widget
                            ? cellData // Render as widget
                            : Text(cellData
                                .toString()), // Render as text otherwise
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizableColumnHeader(int index, String title) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          columnWidths[index] =
              (columnWidths[index] + details.delta.dx).clamp(50.0, 400.0);
        });
      },
      child: Container(
        width: columnWidths[index],
        height: 50, // Header height
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          color: Colors.grey[200],
        ),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

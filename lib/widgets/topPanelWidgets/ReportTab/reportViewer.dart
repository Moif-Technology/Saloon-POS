import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:docx_template/docx_template.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:xml/xml.dart' as xml;

class ReportViewerDialog extends ConsumerStatefulWidget {
  final bool isSummary; // ✅ Add this

  // ✅ Make `isSummary` optional with default value `false`
  const ReportViewerDialog({super.key, this.isSummary = false});

  @override
  _ReportViewerDialogState createState() => _ReportViewerDialogState();
}

class _ReportViewerDialogState extends ConsumerState<ReportViewerDialog> {
  Future<Uint8List>? _pdfFuture;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isPanMode = false;

  double _zoomLevel = 1.0;
  int _totalPages = 1;
  int _currentPage = 1;
String selectedFormat = "PDF"; // Default format
static const Color _primaryColor = Color(0xFF521C1D);

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _saveFile() async {
    String? selectedFormat = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select File Format"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                  title: Text("PDF"),
                  onTap: () => Navigator.pop(context, "pdf")),
              ListTile(
                  title: Text("CSV"),
                  onTap: () => Navigator.pop(context, "csv")),
              ListTile(
                  title: Text("Excel (XLSX)"),
                  onTap: () => Navigator.pop(context, "xlsx")),
              ListTile(
                  title: Text("Word (DOCX)"),
                  onTap: () => Navigator.pop(context, "docx")),
              ListTile(
                  title: Text("XML"),
                  onTap: () => Navigator.pop(context, "xml")),
            ],
          ),
        );
      },
    );

    if (selectedFormat == null) return;

    Uint8List fileBytes;
    switch (selectedFormat) {
      case "pdf":
        fileBytes = await _pdfFuture!;
        break;
      case "csv":
        fileBytes = await _generateCSV();
        break;
      case "xlsx":
        fileBytes = await _generateExcel();
        break;
      case "docx":
        fileBytes = await _generateDocx();
        break;
      case "xml":
        fileBytes = await _generateXML();
        break;
      default:
        return;
    }

    String? filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report As',
      fileName: "Sales_Report.$selectedFormat",
      type: FileType.custom,
      allowedExtensions: [selectedFormat],
    );

    if (filePath != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      print("File saved at: $filePath");
    }
  }

  Future<Uint8List> _generatePDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text("Sales Report - Generated in PDF"),
          );
        },
      ),
    );
    return pdf.save();
  }

  /// **Generate Properly Formatted Excel**
  Future<Uint8List> _generateExcel() async {
    final reportData = ref.read(reportDataProvider);

    var excel = ex.Excel.createExcel();
    ex.Sheet sheet = excel[excel.getDefaultSheet()!];

    // Extract headers dynamically from the first row of data
    List<String> headers = reportData.first.keys.toList();

    // Add headers to the sheet
    sheet.appendRow(headers.map((header) => ex.TextCellValue(header)).toList());

    // Add data rows
    for (var row in reportData) {
      sheet.appendRow(headers
          .map((header) => ex.TextCellValue(row[header].toString()))
          .toList());
    }

    // Save the Excel file
    List<int>? bytes = excel.save();
    return Uint8List.fromList(bytes!);
  }

  /// **Generate Properly Formatted CSV**
  Future<Uint8List> _generateCSV() async {
    final reportData = ref.read(reportDataProvider);

    // Extract headers dynamically from the first row of data
    List<String> headers = reportData.first.keys.toList();

    // Convert the data to CSV format
    List<List<String>> csvData = [headers];
    for (var row in reportData) {
      csvData.add(headers.map((header) => row[header].toString()).toList());
    }

    String csvString = const ListToCsvConverter().convert(csvData);
    return Uint8List.fromList(csvString.codeUnits);
  }

  Future<Uint8List> _generateDocx() async {
    final reportData = ref.read(reportDataProvider);
    final data = await rootBundle.load('assets/template.docx');
    final bytes = data.buffer.asUint8List();
    final docx = await DocxTemplate.fromBytes(bytes);

    Content content = Content();
    List<RowContent> tableRows = [];

    // Extract headers dynamically from the first row of data
    List<String> headers = reportData.first.keys.toList();

    for (var row in reportData) {
      Map<String, Content> rowData = {};

      for (int i = 0; i < headers.length; i++) {
        rowData["column$i"] =
            TextContent("column$i", row[headers[i]].toString());
      }

      tableRows.add(RowContent(rowData));
    }

    TableContent table = TableContent("table", tableRows);
    content.add(table);

    final generatedDocx = await docx.generate(content);
    return Uint8List.fromList(generatedDocx ?? []);
  }

  Uint8List _generateRTF() {
    final buffer = StringBuffer();
    buffer.writeln(r"{\rtf1\ansi\deff0 {\fonttbl {\f0 Arial;}}");
    buffer.writeln(r"\b Sales Report - Generated in RTF\b0");
    buffer.writeln("}");

    return Uint8List.fromList(buffer.toString().codeUnits);
  }

  Future<Uint8List> _generateXML() async {
    final reportData = ref.read(reportDataProvider);

    // Create an XML builder
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    // Start building the XML structure
    builder.element('SalesReport', nest: () {
      for (var row in reportData) {
        builder.element('Entry', nest: () {
          // Dynamically add all fields from the row
          row.forEach((key, value) {
            builder.element(key, nest: value.toString());
          });
        });
      }
    });

    // Convert the XML document to a string
    final xmlDocument = builder.buildDocument();
    final xmlString = xmlDocument.toXmlString(pretty: true);

    // Return the XML as Uint8List
    return Uint8List.fromList(xmlString.codeUnits);
  }

  /// ✅ **Generate and store a PDF**
  Future<void> _generatePdf() async {
    setState(() {
      _pdfFuture = null;
    });

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final reportData = ref.read(reportDataProvider);
    final currencyPrecession = ref.read(currencyPrecessionProvider) ?? "0.00";
    final decParts = currencyPrecession.split('.');
    final currencyDecimals = decParts.length > 1 ? decParts[1].length : 2;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1),
            ),
            padding: pw.EdgeInsets.all(20),
            margin: pw.EdgeInsets.all(10),
            child: pw.Column(
              children: [
                // ✅ Report Title
                pw.Text("MW4, Mussafah, Abu Dhabi, U.A.E",
                    style: pw.TextStyle(fontSize: 14, font: boldFont)),
                pw.SizedBox(height: 4),
                pw.Text("Sales Report - Location Wise",
                    style: pw.TextStyle(
                        fontSize: 12,
                        font: boldFont,
                        decoration: pw.TextDecoration.underline)),
                pw.SizedBox(height: 10),

                // ✅ Show correct table based on `isSummary`
                widget.isSummary
                    ? _buildSummaryTable(reportData, font, boldFont, currencyDecimals)
                    : _buildDetailedTable(reportData, font, boldFont, currencyDecimals),
              ],
            ),
          );
        },
      ),
    );

    Uint8List pdfBytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/Area_report.pdf");
    await file.writeAsBytes(pdfBytes);

    setState(() {
      _pdfFuture = Future.value(pdfBytes);
    });
  }

  /// ✅ **Summary Table (Grouped by Area) with Net Total**
  pw.Widget _buildSummaryTable(
      List<dynamic> reportData, pw.Font font, pw.Font boldFont, int currencyDecimals) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: pw.FlexColumnWidth(3), // Location
        1: pw.FlexColumnWidth(2), // Sales Amount
        2: pw.FlexColumnWidth(2), // Discount
        3: pw.FlexColumnWidth(2), // Taxable Amount
        4: pw.FlexColumnWidth(2), // Tax
        5: pw.FlexColumnWidth(2), // Net Amount
      },
      children: [
        // ✅ **Header Row**
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _tableHeader("Location", boldFont),
            _tableHeader("Sales Amount", boldFont),
            _tableHeader("Discount", boldFont),
            _tableHeader("Taxable Amount", boldFont),
            _tableHeader("Tax", boldFont),
            _tableHeader("Net Amount", boldFont),
          ],
        ),

        // ✅ **Data Rows** (parse numbers - API returns strings, use currency precision)
        ...reportData.map((row) {
          bool isNetTotal = row["AreaName"] == "Net Total";
          return pw.TableRow(
            decoration:
                isNetTotal ? pw.BoxDecoration(color: PdfColors.grey400) : null,
            children: [
              _tableCell(isNetTotal ? "Net Total:" : row["AreaName"]?.toString() ?? '',
                  isNetTotal ? boldFont : font),
              _tableCell(_parseNum(row["SubTotalM"]).toStringAsFixed(currencyDecimals),
                  isNetTotal ? boldFont : font),
              _tableCell(_parseNum(row["BillDisc"]).toStringAsFixed(currencyDecimals),
                  isNetTotal ? boldFont : font),
              _tableCell(_parseNum(row["TaxableAmount"]).toStringAsFixed(currencyDecimals),
                  isNetTotal ? boldFont : font),
              _tableCell(_parseNum(row["Tax1AmountM"]).toStringAsFixed(currencyDecimals),
                  isNetTotal ? boldFont : font),
              _tableCell(_parseNum(row["Amount"]).toStringAsFixed(currencyDecimals),
                  isNetTotal ? boldFont : font),
            ],
          );
        }),
      ],
    );
  }

  /// ✅ **Build Detailed Table (Now Uses Backend Totals & Fixes Net Total Issue)**
  pw.Widget _buildDetailedTable(
      List<dynamic> reportData, pw.Font font, pw.Font boldFont, int currencyDecimals) {
    List<pw.Widget> content = [];
    Map<String, List<Map<String, dynamic>>> groupedData = {};

    // ✅ **Group data by Area Name**
    for (var row in reportData) {
      if (row["AreaName"] != "Net Total") {
        groupedData.putIfAbsent(row["AreaName"], () => []).add(row);
      }
    }

    double grandTotalSales = 0,
        grandTotalDiscount = 0,
        grandTotalTaxable = 0,
        grandTotalTax = 0,
        grandTotalNet = 0;

    groupedData.forEach((area, rows) {
      double subTotalSales = 0,
          subTotalDiscount = 0,
          subTotalTaxable = 0,
          subTotalTax = 0,
          subTotalNet = 0;

      // ✅ **Area Header**
      content.add(
        pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            border: pw.Border.all(width: 0.5),
          ),
          child: pw.Text(
            area.toUpperCase(),
            style: pw.TextStyle(fontSize: 12, font: boldFont),
          ),
        ),
      );

      // ✅ **Table Header**
      content.add(
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: {
            0: pw.FlexColumnWidth(2), // Bill Date
            1: pw.FlexColumnWidth(2), // Sales Amount
            2: pw.FlexColumnWidth(2), // Discount
            3: pw.FlexColumnWidth(2), // Taxable Amount
            4: pw.FlexColumnWidth(2), // Tax
            5: pw.FlexColumnWidth(2), // Net Amount
          },
          children: [
            // ✅ **Header Row**
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _tableHeader("Bill Date", boldFont),
                _tableHeader("Sales Amount", boldFont),
                _tableHeader("Discount", boldFont),
                _tableHeader("Taxable Amount", boldFont),
                _tableHeader("Tax", boldFont),
                _tableHeader("Net Amount", boldFont),
              ],
            ),
            // ✅ **Data Rows** (parse numbers - API returns strings, use currency precision)
            ...rows.map((row) {
              subTotalSales += _parseNum(row["SubTotalM"]);
              subTotalDiscount += _parseNum(row["BillDisc"]);
              subTotalTaxable += _parseNum(row["TaxableAmount"]);
              subTotalTax += _parseNum(row["Tax1AmountM"]);
              subTotalNet += _parseNum(row["Amount"]);

              return pw.TableRow(
                children: [
                  _tableCell(row["BillDate"]?.toString() ?? '', font),
                  _tableCell(_parseNum(row["SubTotalM"]).toStringAsFixed(currencyDecimals), font),
                  _tableCell(_parseNum(row["BillDisc"]).toStringAsFixed(currencyDecimals), font),
                  _tableCell(_parseNum(row["TaxableAmount"]).toStringAsFixed(currencyDecimals), font),
                  _tableCell(_parseNum(row["Tax1AmountM"]).toStringAsFixed(currencyDecimals), font),
                  _tableCell(_parseNum(row["Amount"]).toStringAsFixed(currencyDecimals), font),
                ],
              );
            }),
            // ✅ **Subtotal Row** (use currency precision)
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableHeader("$area Total:", boldFont),
                _tableCell(subTotalSales.toStringAsFixed(currencyDecimals), boldFont),
                _tableCell(subTotalDiscount.toStringAsFixed(currencyDecimals), boldFont),
                _tableCell(subTotalTaxable.toStringAsFixed(currencyDecimals), boldFont),
                _tableCell(subTotalTax.toStringAsFixed(currencyDecimals), boldFont),
                _tableCell(subTotalNet.toStringAsFixed(currencyDecimals), boldFont),
              ],
            ),
          ],
        ),
      );

      grandTotalSales += subTotalSales;
      grandTotalDiscount += subTotalDiscount;
      grandTotalTaxable += subTotalTaxable;
      grandTotalTax += subTotalTax;
      grandTotalNet += subTotalNet;
    });

    // ✅ **Final Net Total Row (Fixing the Issue)**
    content.add(pw.SizedBox(height: 10));
    content.add(
      pw.Table(
        border: pw.TableBorder.all(width: 0.8),
        columnWidths: {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(2),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(2),
          4: pw.FlexColumnWidth(2),
          5: pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey400),
            children: [
              _tableHeader("Net Total:", boldFont),
              _tableCell(grandTotalSales.toStringAsFixed(currencyDecimals), boldFont),
              _tableCell(grandTotalDiscount.toStringAsFixed(currencyDecimals), boldFont),
              _tableCell(grandTotalTaxable.toStringAsFixed(currencyDecimals), boldFont),
              _tableCell(grandTotalTax.toStringAsFixed(currencyDecimals), boldFont),
              _tableCell(grandTotalNet.toStringAsFixed(currencyDecimals), boldFont),
            ],
          ),
        ],
      ),
    );

    return pw.Column(children: content);
  }

  /// Parse numeric value (API returns strings)
  double _parseNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// **Helper Functions**
  pw.Widget _tableHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 10, font: font),
          textAlign: pw.TextAlign.center),
    );
  }

  pw.Widget _tableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 10, font: font),
          textAlign: pw.TextAlign.right),
    );
  }

  @override
Widget build(BuildContext context) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
    child: Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          _buildHeader("Report Preview"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildToolbar(),
                  const SizedBox(height: 8),
                  Expanded(
              child: FutureBuilder<Uint8List>(
                future: _pdfFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text("Error loading PDF",
                            style: TextStyle(color: Colors.red)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text("No PDF to display",
                            style: TextStyle(color: Colors.grey)));
                  } else {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26, width: 1),
                        ),
                        child: SfPdfViewer.memory(
                          snapshot.data!,
                          controller: _pdfViewerController,
                          enableDoubleTapZooming: true,
                          interactionMode: _isPanMode
                              ? PdfInteractionMode.pan
                              : PdfInteractionMode.selection,
                          onDocumentLoaded: (details) {
                            setState(() {
                               _totalPages = details.document.pages.count;
                              _currentPage = 1;
                            });
                          },
                          onPageChanged: (details) {
                            setState(() {
                              _currentPage = details.newPageNumber;
                            });
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
                           ),
                  const SizedBox(height: 10),
                  _buildBottomToolbar(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
/// Brand header — title left, Close (✕) top-right (40×40 touch target)
Widget _buildHeader(String title) {
  return Container(
    constraints: const BoxConstraints(minHeight: 56),
    padding: const EdgeInsets.only(left: 20, right: 8),
    decoration: const BoxDecoration(
      color: _primaryColor,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
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

  /// **Toolbar with Navigation & Zoom Controls**
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(Icons.first_page, _goToFirstPage),
          _buildIconButton(Icons.navigate_before, _previousPage),
          _buildPageIndicator(),
          _buildIconButton(Icons.navigate_next, _nextPage),
          _buildIconButton(Icons.last_page, _goToLastPage),
          VerticalDivider(),
          _buildIconButton(Icons.zoom_in, _zoomIn),
          _buildIconButton(Icons.zoom_out, _zoomOut),
          _buildIconButton(Icons.fit_screen, _fitToWidth),
          _buildTogglePanButton(),
        ],
      ),
    );
  }

 /// **Bottom Toolbar with Save & Print** (bottom-right, POS standard)
Widget _buildBottomToolbar() {
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          Icons.save,
          "Save Report",
          _saveFile,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          Icons.print,
          "Print",
          _printReport,
          isPrimary: true,
        ),
      ],
    ),
  );
}

  

/// Button Builder — [isPrimary] = solid brand; otherwise outlined secondary
Widget _buildActionButton(
  IconData icon,
  String label,
  VoidCallback onPressed, {
  bool isPrimary = false,
}) {
  const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );
  const textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  if (isPrimary) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: textStyle),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _primaryColor,
        padding: padding,
        shape: shape,
        elevation: 0,
      ),
    );
  }

  return OutlinedButton.icon(
    icon: Icon(icon, size: 18),
    label: Text(label, style: textStyle),
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: _primaryColor,
      backgroundColor: Colors.white,
      padding: padding,
      shape: shape,
      side: BorderSide(color: Colors.grey.shade400, width: 1.5),
    ),
  );
}

  Future<void> _printReport() async {
    print("Printing Report...");
  }

  /// **Page Indicator with Editable Field**
  Widget _buildPageIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(border: OutlineInputBorder()),
            controller: TextEditingController(text: _currentPage.toString()),
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              int page = int.tryParse(value) ?? 1;
              if (page > 0 && page <= _totalPages) {
                _pdfViewerController.jumpToPage(page);
              }
            },
          ),
        ),
        Text(" / $_totalPages", style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildDropdown() {
    return Row(
      children: [
        Text("Format:", style: TextStyle(fontSize: 16)),
        const SizedBox(width: 5),
        DropdownButton<String>(
          value: selectedFormat,
          onChanged: (String? newValue) {
            setState(() {
              selectedFormat = newValue!;
            });
          },
          items: <String>["PDF", "Word"]
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  Widget _buildTogglePanButton() {
    return IconButton(
      icon: Icon(_isPanMode ? Icons.pan_tool : Icons.touch_app),
      onPressed: () {
        setState(() {
          _isPanMode = !_isPanMode;
        });
      },
    );
  }

  void _goToFirstPage() => _pdfViewerController.firstPage();
  void _previousPage() => _pdfViewerController.previousPage();
  void _nextPage() => _pdfViewerController.nextPage();
  void _goToLastPage() => _pdfViewerController.lastPage();
  void _zoomIn() => _pdfViewerController.zoomLevel += 0.25;
  void _zoomOut() => _pdfViewerController.zoomLevel -= 0.25;
  void _fitToWidth() => _pdfViewerController.zoomLevel = 1.0;

  Future<void> _savePdf() async {}
  // Future<void> _printReport() async {}
}

import 'package:flutter/material.dart';

class AddCustomerDialog extends StatefulWidget {
  @override
  _AddCustomerDialogState createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers with late initialization
  late TextEditingController customerIdController;
  late TextEditingController customerCodeController;
  late TextEditingController searchController;
  late TextEditingController customerNameController;
  late TextEditingController customerNameArabicController;
  late TextEditingController custTRNController;
  late TextEditingController addressController;
  late TextEditingController addressArabicController;
  late TextEditingController areaController;
  late TextEditingController areaArabicController;
  late TextEditingController telephoneController;
  late TextEditingController mobileController;
  late TextEditingController mobile2Controller;
  late TextEditingController creditBalanceController;
  late TextEditingController creditLimitController;
  late TextEditingController advanceAmountController;
  bool isUpdate = false;

  List<dynamic> customers = []; // Fetched customers
  bool isLoading = true; // Loading state flag

  // Payment mode dropdown value
  String _selectedPaymentMode = 'CASH';

  @override
  void initState() {
    super.initState();
    // Initialize all controllers
    _initializeControllers();
    _fetchCustomers(); // Fetch customers on load
    // Add listeners for debugging
    _addControllerListeners();
  }

  void _initializeControllers() {
    customerIdController = TextEditingController();
    customerCodeController = TextEditingController();
    searchController = TextEditingController();
    customerNameController = TextEditingController();
    customerNameArabicController = TextEditingController();
    custTRNController = TextEditingController();
    addressController = TextEditingController();
    addressArabicController = TextEditingController();
    areaController = TextEditingController();
    areaArabicController = TextEditingController();
    telephoneController = TextEditingController();
    mobileController = TextEditingController();
    mobile2Controller = TextEditingController();
    creditBalanceController = TextEditingController();
    creditLimitController = TextEditingController();
    advanceAmountController = TextEditingController();
  }

  void _fetchCustomers({String searchTerm = ''}) async {
    try {
      setState(() => isLoading = true); // Show loading indicator
      final response = <dynamic>[];

      setState(() {
        customers = response; // Populate the customers list
        isLoading = false; // Hide loading indicator
      });

      print('Fetched Customers: $customers');
    } catch (error) {
      setState(() => isLoading = false); // Hide loading indicator on error
      _showErrorSnackBar('Error fetching customers: $error');
    }
  }

// Call _fetchCustomers on input change (debounced)
  void _onSearchChanged(String searchTerm) {
    _fetchCustomers(searchTerm: searchTerm);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addControllerListeners() {
    // Add listeners to track changes
    customerNameController.addListener(() {
      print('Customer Name Changed: ${customerNameController.text}');
    });

    customerNameArabicController.addListener(() {
      print(
          'Customer Name Arabic Changed: ${customerNameArabicController.text}');
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    customerIdController.dispose();
    customerCodeController.dispose();
    searchController.dispose();
    customerNameController.dispose();
    customerNameArabicController.dispose();
    custTRNController.dispose();
    addressController.dispose();
    addressArabicController.dispose();
    areaController.dispose();
    areaArabicController.dispose();
    telephoneController.dispose();
    mobileController.dispose();
    mobile2Controller.dispose();
    creditBalanceController.dispose();
    creditLimitController.dispose();
    advanceAmountController.dispose();
  }

  // Function to generate customer code
  Future<void> _generateCustomerCode() async {
    try {
      setState(() {
        customerCodeController.text = 'NEW';
      });
    } catch (error) {
      _showErrorSnackBar('Error generating customer code: $error');
    }
  }

  // Comprehensive validation method
  bool _validateForm() {
    if (_formKey.currentState == null) return false;

    // Check if the form is valid
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill all required fields correctly');
      return false;
    }

    // Additional custom validations
    if (customerCodeController.text.trim().isEmpty) {
      _showErrorSnackBar('Customer Code is required');
      return false;
    }

    return true;
  }

  // Save customer method
  Future<void> _saveCustomer() async {
    // Validate form
    if (!_validateForm()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Customer "${customerNameController.text.trim()}" saved in mock mode.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop({
      'CustomerID': customerIdController.text.trim().isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : customerIdController.text.trim(),
      'CustomerCode': customerCodeController.text.trim(),
      'CustomerName': customerNameController.text.trim(),
      'Telephone': telephoneController.text.trim(),
      'MobileNo': mobileController.text.trim(),
      'CustTRN': custTRNController.text.trim(),
      'Address': addressController.text.trim(),
    });
  }

  void _populateForm(Map<String, dynamic> customer) {
    setState(() {
      customerIdController.text = customer['CustomerID'].toString();
      customerCodeController.text = customer['CustomerCode'] ?? '';
      customerNameController.text = customer['CustomerName'] ?? '';
      customerNameArabicController.text = customer['CustomerNameArabic'] ?? '';
      custTRNController.text = customer['CustTRN'] ?? '';
      addressController.text = customer['Address'] ?? '';
      addressArabicController.text = customer['AddressArabic'] ?? '';
      areaController.text = customer['Area'] ?? '';
      areaArabicController.text = customer['AreaArabic'] ?? '';
      telephoneController.text = customer['Telephone'] ?? '';
      mobileController.text = customer['MobileNo'] ?? '';
      mobile2Controller.text = customer['MobileNo2'] ?? '';
      creditBalanceController.text =
          customer['CreditBalance']?.toString() ?? '';
      creditLimitController.text = customer['CreditLimit']?.toString() ?? '';
      advanceAmountController.text =
          customer['AdvanceAmount']?.toString() ?? '';
      _selectedPaymentMode = customer['PaymentMode'] ?? 'CASH';
      isUpdate = true; // Set to true if you want to update the customer
    });
  }

  // Clear form method
  void _clearForm() {
    // Reset all controllers
    customerCodeController.clear();
    customerNameController.clear();
    customerNameArabicController.clear();
    custTRNController.clear();
    addressController.clear();
    addressArabicController.clear();
    areaController.clear();
    areaArabicController.clear();
    telephoneController.clear();
    mobileController.clear();
    mobile2Controller.clear();
    creditBalanceController.clear();
    creditLimitController.clear();
    advanceAmountController.clear();

    // Reset payment mode
    setState(() {
      _selectedPaymentMode = 'CASH';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 900,
        height: 650,
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left ```dart
              // Left-side form with two columns for input fields
              Container(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Code Generation Field
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            'Customer Code',
                            controller: customerCodeController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a customer code';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _generateCustomerCode,
                          icon: Icon(Icons.autorenew,
                              size: 18, color: Colors.white),
                          label:
                              Text('Generate', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF521C1D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Rest of the form fields in two columns
                    buildRowOfTextFields(
                      buildTextField('Customer Name',
                          controller: customerNameController),
                      buildTextField('Cust. Name Arabic',
                          controller: customerNameArabicController),
                    ),
                    SizedBox(height: 10),
                    buildRowOfTextFields(
                      buildTextField('Cust. TRN',
                          controller: custTRNController),
                      buildTextField('Address',
                          controller: addressController, maxLines: 2),
                    ),
                    SizedBox(height: 10),
                    buildRowOfTextFields(
                      buildTextField('Address Arabic',
                          controller: addressArabicController, maxLines: 2),
                      buildTextField('Area', controller: areaController),
                    ),
                    SizedBox(height: 10),
                    buildRowOfTextFields(
                      buildTextField('Area Arabic',
                          controller: areaArabicController),
                      buildTextField('Telephone',
                          controller: telephoneController),
                    ),
                    SizedBox(height: 10),
                    buildRowOfTextFields(
                      buildTextField('Mobile', controller: mobileController),
                      buildTextField('MobileNo 2',
                          controller: mobile2Controller),
                    ),
                    SizedBox(height: 10),
                    buildRowOfTextFields(
                      buildTextField('Credit Balance',
                          controller: creditBalanceController),
                      buildTextField('Credit Limit',
                          controller: creditLimitController),
                    ),
                    SizedBox(height: 10),
                    buildRowOfTextFields(
                      Row(
                        children: [
                          Expanded(
                            child: buildTextField('Advance Amount',
                                controller: advanceAmountController),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: buildDropdown('Pay Mode'),
                          ),
                        ],
                      ),
                      SizedBox(),
                    ),
                    // Push buttons to the bottom using Spacer
                    Spacer(),
                    // New and Update buttons with increased size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildButton('Save', Icons.add,
                            isPrimary: true,
                            buttonSize: 70,
                            onPressed: _saveCustomer),
                        buildButton('Update', Icons.update,
                            isPrimary: true,
                            buttonSize: 70,
                            onPressed: _saveCustomer),
                        buildButton('Clear', Icons.clear,
                            isPrimary: true, // Secondary button style
                            buttonSize: 70,
                            onPressed:
                                _clearForm // Call _clearForm() when pressed
                            ),
                      ],
                    ),
                  ],
                ),
              ),

              VerticalDivider(thickness: 1, color: Color(0xFFA0A0A0)),
              // Right-side table with search at the top
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Field at the Top
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, code, area, telephone...',
                          prefixIcon:
                              Icon(Icons.search, color: Color(0xFF521C1D)),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFA0A0A0)),
                          ),
                        ),
                        onChanged: (value) {
                          _onSearchChanged(
                              value); // Call the debounced search function
                        },
                      ),
                    ),
                    // Table Header
                    Row(
                      children: [
                        buildTableHeader('Code'),
                        buildTableHeader('Customer ID'),
                        buildTableHeader('Customer Name'),
                        buildTableHeader('Area'),
                        buildTableHeader('Telephone'),
                        buildTableHeader('Mobile'),
                      ],
                    ),
                    Divider(color: Color(0xFFA0A0A0)),
                    // Table Body with Dummy Data
                    Expanded(
                      child: isLoading
                          ? Center(
                              child:
                                  CircularProgressIndicator()) // Show loading spinner
                          : customers.isEmpty
                              ? Center(
                                  child: Text(
                                      "No customers found")) // Fallback for no data
                              : ListView.builder(
                                  itemCount: customers.length,
                                  itemBuilder: (context, index) {
                                    final customer = customers[index];
                                    return GestureDetector(
                                      onTap: () => _populateForm(customer),
                                      child: Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        color: index % 2 == 0
                                            ? Color(
                                                0xFFF9F9F9) // Alternate row color
                                            : Colors.white,
                                        child: Row(
                                          children: [
                                            buildTableCell(
                                                customer['CustomerCode'] ?? ''),
                                            buildTableCell(
                                                customer['CustomerID'] ?? ''),
                                            buildTableCell(
                                                customer['CustomerName'] ?? ''),
                                            buildTableCell(
                                                customer['City'] ?? ''),
                                            buildTableCell(
                                                customer['Telephone'] ?? ''),
                                            buildTableCell(
                                                customer['MobileNo'] ?? ''),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),

                    Divider(color: Color(0xFFA0A0A0)),
                    // Additional Buttons at the Bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        buildButton('Select', Icons.check_circle,
                            isPrimary: true, onPressed: () {}),
                        SizedBox(width: 10),
                        buildButton('Print', Icons.print,
                            isPrimary: true, onPressed: () {}),
                        SizedBox(width: 10),
                        buildButton('Num Pad', Icons.dialpad,
                            isPrimary: true, onPressed: () {}),
                        SizedBox(width: 10),
                        buildCloseButton(context), // Separate close button
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRowOfTextFields(Widget firstField, Widget secondField) {
    return Row(
      children: [
        Expanded(child: firstField),
        SizedBox(width: 12),
        Expanded(child: secondField),
      ],
    );
  }

  Widget buildTextField(String label,
      {TextEditingController? controller,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold // Add this line to make text bold
          ),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      validator: validator,
    );
  }

  Widget buildDropdown(String label) {
    return DropdownButtonFormField(
      value: _selectedPaymentMode,
      items: [
        DropdownMenuItem(
            value: 'CASH', child: Text('CASH', style: TextStyle(fontSize: 12))),
        DropdownMenuItem(
            value: 'CREDIT',
            child: Text('CREDIT', style: TextStyle(fontSize: 12))),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPaymentMode = value.toString();
        });
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Color(0xFFA0A0A0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
    );
  }

  Widget buildButton(String label, IconData icon,
      {bool isPrimary = true,
      double buttonSize = 70,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(buttonSize, 40),
        backgroundColor: isPrimary ? Color(0xFF521C1D) : Color(0xFFA0A0A0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget buildCloseButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: Icon(Icons.close, size: 16),
      label: Text('Close', style: TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(70, 40),
        backgroundColor: Color(0xFFA0A0A0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget buildTableHeader(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF521C1D)),
        ),
      ),
    );
  }

  Widget buildTableCell(String content) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/core/providers/api_service_provider.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/core/providers/update_provider.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:my_app/utils/sessionStorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class MainLoginPage extends ConsumerStatefulWidget {
  @override
  _MainLoginPageState createState() => _MainLoginPageState();
}

class _MainLoginPageState extends ConsumerState<MainLoginPage>
    with WindowListener {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  TextEditingController? focusedController;
  String databaseValue = "SERVER";
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  String loginAs = "Admin";

  // PIN mode
  bool _pinMode = false;
  String _pin = '';
  String _storedCompanyId = '';
  List<Map<String, dynamic>> _staffList = [];
  Map<String, dynamic>?
      _selectedStaff; // null = show picker, non-null = show PIN
  bool _loadingStaff = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      configureLoginWindow();
    }

    // Check if device has been used before (companyId stored) → default to PIN mode
    _loadStoredCompanyId();

    // Set initial focus to username field (post-frame so RenderBox is laid out, fixes web assertion).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pinMode) {
        usernameFocusNode.requestFocus();
        focusedController = usernameController;
      }

      // Dev-only: prefill credentials so you just press Login.
      // kDebugMode is false in release builds, so this never ships.
      if (kDebugMode && !_pinMode) {
        usernameController.text = "";
        passwordController.text = "12345678";
      }
    });

    // Update focus listeners to properly handle focus changes
    usernameFocusNode.addListener(() {
      if (usernameFocusNode.hasFocus) {
        setState(() {
          focusedController = usernameController;
        });
      }
    });

    passwordFocusNode.addListener(() {
      if (passwordFocusNode.hasFocus) {
        setState(() {
          focusedController = passwordController;
        });
      }
    });
  }

  Future<void> _loadStoredCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getString('posCompanyId') ?? '';
    if (cid.isNotEmpty && mounted) {
      setState(() {
        _storedCompanyId = cid;
        _pinMode = true;
      });
      _loadStaffList(cid);
    }
  }

  Future<void> _loadStaffList(String cid) async {
    final companyId = int.tryParse(cid);
    if (companyId == null || companyId < 1) return;
    if (mounted)
      setState(() {
        _loadingStaff = true;
      });
    try {
      final apiService = ref.read(apiServiceProvider);
      final list = await apiService.fetchPosStaffList(companyId);
      if (mounted)
        setState(() {
          _staffList = list;
          _loadingStaff = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loadingStaff = false;
        });
    }
  }

  Future<void> _saveCompanyId(String companyId) async {
    if (companyId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('posCompanyId', companyId);
    _storedCompanyId = companyId;
  }

  Future<void> _clearStoredCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('posCompanyId');
    if (mounted) {
      setState(() {
        _storedCompanyId = '';
        _pinMode = false;
        _pin = '';
        _staffList = [];
        _selectedStaff = null;
      });
    }
  }

  Future<void> _handlePinLogin() async {
    if (_pin.length != 4) {
      setState(() {
        _errorMessage = "Enter your 4-digit PIN.";
      });
      return;
    }
    final cid = int.tryParse(_storedCompanyId);
    if (cid == null || cid < 1) {
      setState(() {
        _errorMessage = "No company linked. Login with email first.";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final staffPk = _selectedStaff == null
          ? null
          : int.tryParse(_selectedStaff!['staffPk'].toString());
      final loginResponse =
          await apiService.pinLogin(_pin, cid, staffPk: staffPk);
      if (!mounted) return;

      final stationId = loginResponse['stationId']?.toString();
      final staffName = loginResponse['staffName']?.toString();
      final staffID = loginResponse['staffID']?.toString();
      final accessToken = loginResponse['accessToken']?.toString();
      final refreshToken = loginResponse['refreshToken']?.toString();
      final subscription = loginResponse['subscription'] is Map
          ? Map<String, dynamic>.from(loginResponse['subscription'] as Map)
          : null;
      final features = loginResponse['features'] is Map
          ? Map<String, dynamic>.from(loginResponse['features'] as Map)
          : <String, dynamic>{};
      final limits = loginResponse['limits'] is Map
          ? Map<String, dynamic>.from(loginResponse['limits'] as Map)
          : <String, dynamic>{};
      final permissions = loginResponse['permissions'] is List
          ? List<dynamic>.from(loginResponse['permissions'] as List)
          : <dynamic>[];

      if (stationId != null &&
          stationId.isNotEmpty &&
          staffName != null &&
          staffName.isNotEmpty &&
          staffID != null &&
          staffID.isNotEmpty) {
        SessionManager().setSession(
          stationId: stationId,
          staffName: staffName,
          staffID: staffID,
          accessToken: accessToken,
          refreshToken: refreshToken,
          subscription: subscription,
          features: features,
          limits: limits,
          permissions: permissions,
        );
        await SessionStorage.saveSession(
          stationId,
          staffName,
          staffID,
          accessToken: accessToken,
          refreshToken: refreshToken,
          subscription: subscription,
          features: features,
          limits: limits,
          permissions: permissions,
        );
        if (!mounted) return;
        ref.read(subscriptionProvider.notifier).state = subscription;
        ref.read(featuresProvider.notifier).state = features;
        ref.read(limitsProvider.notifier).state = limits;
        ref.read(permissionsProvider.notifier).state = permissions;

        final parametersResponse = await apiService.fetchParameters();
        if (!mounted) return;
        final privilegesResponse = await apiService.fetchPrivileges();
        if (!mounted) return;
        ref.read(privilegesProvider.notifier).state = privilegesResponse;

        final tax1 = (parametersResponse['Tax1'] as num?)?.toDouble();
        final currencyPrecession = parametersResponse['currencyPrecession'];
        final reportStartTime = parametersResponse['reportStartTime'];
        final reportEndTime = parametersResponse['reportEndTime'];
        final pendingKotCheck =
            parametersResponse['pendingKotCheck'] as int? ?? 0;
        final ISWaiterMandotory =
            parametersResponse['ISWaiterMandotory'] as int? ?? 0;
        final ClearAfterKOTSave =
            parametersResponse['ClearAfterKOTSave'] as int? ?? 0;
        final SaveKOTonSettlement =
            parametersResponse['SaveKOTonSettlement'] as int? ?? 0;

        if (tax1 != null &&
            currencyPrecession != null &&
            reportStartTime != null &&
            reportEndTime != null) {
          ref.read(tax1Provider.notifier).state = tax1;
          ref.read(currencyPrecessionProvider.notifier).state =
              currencyPrecession;
          ref.read(StartTimeProvider.notifier).state = reportStartTime;
          ref.read(EndTimeProvider.notifier).state = reportEndTime;
          ref.read(pendingKotCheckProvider.notifier).state = pendingKotCheck;
          ref.read(ISWaiterMandotoryProvider.notifier).state =
              ISWaiterMandotory;
          ref.read(ClearAfterKOTSaveProvider.notifier).state =
              ClearAfterKOTSave;
          ref.read(SaveKOTonSettlementProvider.notifier).state =
              SaveKOTonSettlement;
          ref.read(companyDetailsProvider.notifier).state = {
            'heading1':
                (parametersResponse['heading1Counter'] as String?) ?? '',
            'heading2':
                (parametersResponse['heading2Counter'] as String?) ?? '',
            'heading3':
                (parametersResponse['heading3Counter'] as String?) ?? '',
            'heading4':
                (parametersResponse['heading4Counter'] as String?) ?? '',
            'heading5':
                (parametersResponse['heading5Counter'] as String?) ?? '',
            'footer1': (parametersResponse['heading6Counter'] as String?) ?? '',
            'footer2': (parametersResponse['heading7Counter'] as String?) ?? '',
            'taxRegNo':
                (parametersResponse['taxRegistrationNo'] as String?) ?? '',
          };
        }
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => HomeScreen()));
        }
      } else {
        setState(() {
          _errorMessage = "Invalid server response.";
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _pin = '';
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> configureLoginWindow() async {
    if (kIsWeb) return; // window_manager is desktop-only
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: const Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      minimumSize: const Size(1000, 700),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> maximizeWindow() async {
    if (kIsWeb) return;
    await windowManager.setMaximumSize(Size.infinite);
    await windowManager.setMinimumSize(const Size(1, 1));
  }

  Future<void> _handleLogin(BuildContext context) async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both username and password.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);

      // Step 1: Login API call
      final loginResponse = await apiService.login(username, password);
      print("Login Response:");
      print(loginResponse);

      final stationId = loginResponse['stationId']?.toString();
      final staffName = loginResponse['staffName']?.toString();
      final staffID = loginResponse['staffID']?.toString();
      final accessToken = loginResponse['accessToken']?.toString();
      final refreshToken = loginResponse['refreshToken']?.toString();
      final subscription = loginResponse['subscription'] is Map
          ? Map<String, dynamic>.from(loginResponse['subscription'] as Map)
          : null;
      final features = loginResponse['features'] is Map
          ? Map<String, dynamic>.from(loginResponse['features'] as Map)
          : <String, dynamic>{};
      final limits = loginResponse['limits'] is Map
          ? Map<String, dynamic>.from(loginResponse['limits'] as Map)
          : <String, dynamic>{};
      final permissions = loginResponse['permissions'] is List
          ? List<dynamic>.from(loginResponse['permissions'] as List)
          : <dynamic>[];

      if (stationId != null &&
          stationId.isNotEmpty &&
          staffName != null &&
          staffName.isNotEmpty &&
          staffID != null &&
          staffID.isNotEmpty) {
        SessionManager().setSession(
          stationId: stationId,
          staffName: staffName,
          staffID: staffID,
          accessToken: accessToken,
          refreshToken: refreshToken,
          subscription: subscription,
          features: features,
          limits: limits,
          permissions: permissions,
        );

        await SessionStorage.saveSession(
          stationId,
          staffName,
          staffID,
          accessToken: accessToken,
          refreshToken: refreshToken,
          subscription: subscription,
          features: features,
          limits: limits,
          permissions: permissions,
        );
        ref.read(subscriptionProvider.notifier).state = subscription;
        ref.read(featuresProvider.notifier).state = features;
        ref.read(limitsProvider.notifier).state = limits;
        ref.read(permissionsProvider.notifier).state = permissions;

        // Save companyId so future logins can use PIN mode
        final companyId = loginResponse['companyId']?.toString() ?? '';
        await _saveCompanyId(companyId);

        // Step 2: Fetch Parameters API call
        final parametersResponse = await apiService.fetchParameters();

        final privilegesResponse = await apiService.fetchPrivileges();
        ref.read(privilegesProvider.notifier).state = privilegesResponse;

        // Safely access the keys
        final tax1 = (parametersResponse['Tax1'] as num?)?.toDouble();
        final currencyPrecession = parametersResponse['currencyPrecession'];

        final reportStartTime = parametersResponse['reportStartTime'];
        final reportEndTime = parametersResponse['reportEndTime'];
        final pendingKotCheck =
            parametersResponse['pendingKotCheck'] as int? ?? 0;
        final ISWaiterMandotory =
            parametersResponse['ISWaiterMandotory'] as int? ?? 0;
        final ClearAfterKOTSave =
            parametersResponse['ClearAfterKOTSave'] as int? ?? 0;
        final SaveKOTonSettlement =
            parametersResponse['SaveKOTonSettlement'] as int? ?? 0;

        // Save parameters in Riverpod providers
        if (tax1 != null &&
            currencyPrecession != null &&
            reportStartTime != null &&
            reportEndTime != null) {
          ref.read(tax1Provider.notifier).state = tax1;
          ref.read(currencyPrecessionProvider.notifier).state =
              currencyPrecession;
          ref.read(StartTimeProvider.notifier).state = reportStartTime;
          ref.read(EndTimeProvider.notifier).state = reportEndTime;
          ref.read(pendingKotCheckProvider.notifier).state = pendingKotCheck;
          ref.read(ISWaiterMandotoryProvider.notifier).state =
              ISWaiterMandotory;
          ref.read(ClearAfterKOTSaveProvider.notifier).state =
              ClearAfterKOTSave;
          ref.read(SaveKOTonSettlementProvider.notifier).state =
              SaveKOTonSettlement;
          // Company details (for Control Panel)
          ref.read(companyDetailsProvider.notifier).state = {
            'heading1':
                (parametersResponse['heading1Counter'] as String?) ?? '',
            'heading2':
                (parametersResponse['heading2Counter'] as String?) ?? '',
            'heading3':
                (parametersResponse['heading3Counter'] as String?) ?? '',
            'heading4':
                (parametersResponse['heading4Counter'] as String?) ?? '',
            'heading5':
                (parametersResponse['heading5Counter'] as String?) ?? '',
            'footer1': (parametersResponse['heading6Counter'] as String?) ?? '',
            'footer2': (parametersResponse['heading7Counter'] as String?) ?? '',
            'taxRegNo':
                (parametersResponse['taxRegistrationNo'] as String?) ?? '',
          };
          print("Parameters fetched successfully and saved in providers.");
        } else {
          print("Parameters missing or null in the response.");
        }

        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      } else {
        setState(() {
          _errorMessage = "Invalid server response.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Login failed: ${e.toString()}";
      });
      print("Login Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5E132A), // Changed back to original deep red
              Color(0xFF5E132A), // Changed to original maroon
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 1000,
              height: 600,
              margin: EdgeInsets.all(20),
              child: Card(
                elevation: 15,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                        ),
                        padding: EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_pinMode && _selectedStaff == null) ...[
                              // ── Staff picker step ──
                              Text(
                                "Select Staff",
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Tap your name to sign in",
                                style: GoogleFonts.poppins(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 16),
                              Expanded(child: _buildStaffPicker()),
                              SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() {
                                          _pinMode = false;
                                          _pin = '';
                                          _selectedStaff = null;
                                          _errorMessage = null;
                                        }),
                                icon: Icon(Icons.email_outlined,
                                    size: 16, color: Color(0xFF5E132A)),
                                label: Text(
                                  "Login with email instead",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: Color(0xFF5E132A)),
                                ),
                              ),
                              if (_storedCompanyId.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _clearStoredCompanyId(),
                                  icon: Icon(Icons.link_off,
                                      size: 14, color: Colors.grey),
                                  label: Text("Re-enroll device",
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.grey)),
                                ),
                              SizedBox(height: 8),
                              Consumer(
                                builder: (context, ref, _) {
                                  final asyncPkg =
                                      ref.watch(appPackageInfoProvider);
                                  return asyncPkg.when(
                                    data: (pkg) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('v${pkg.version}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[700])),
                                    ),
                                    loading: () => SizedBox.shrink(),
                                    error: (_, __) => SizedBox.shrink(),
                                  );
                                },
                              ),
                            ] else ...[
                              // ── PIN entry or email login step ──
                              Text(
                                _pinMode ? "Enter PIN" : "Welcome Back",
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _pinMode
                                    ? "Enter your 4-digit PIN to sign in"
                                    : "Sign in to continue",
                                style: GoogleFonts.poppins(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 32),
                              if (_pinMode && _selectedStaff != null) ...[
                                Center(
                                  child: Text(
                                    _selectedStaff!['staffName']?.toString() ??
                                        '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5E132A),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                              ],
                              if (_pinMode)
                                _buildPinDots()
                              else
                                _buildLoginForm(),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(_errorMessage!,
                                      style: TextStyle(color: Colors.red)),
                                ),
                              SizedBox(height: 12),
                              // Back to staff list
                              if (_pinMode &&
                                  _selectedStaff != null &&
                                  _staffList.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() {
                                            _selectedStaff = null;
                                            _pin = '';
                                            _errorMessage = null;
                                          }),
                                  icon: Icon(Icons.arrow_back,
                                      size: 16, color: Color(0xFF5E132A)),
                                  label: Text("Back to staff list",
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Color(0xFF5E132A))),
                                ),
                              // Mode toggle
                              TextButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (_pinMode) {
                                          setState(() {
                                            _pinMode = false;
                                            _pin = '';
                                            _selectedStaff = null;
                                            _errorMessage = null;
                                          });
                                        } else {
                                          if (_storedCompanyId.isNotEmpty) {
                                            setState(() {
                                              _pinMode = true;
                                              _pin = '';
                                              _errorMessage = null;
                                            });
                                          }
                                        }
                                      },
                                icon: Icon(
                                  _pinMode
                                      ? Icons.email_outlined
                                      : Icons.dialpad,
                                  size: 16,
                                  color: Color(0xFF5E132A),
                                ),
                                label: Text(
                                  _pinMode
                                      ? "Login with email instead"
                                      : "Login with PIN",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: Color(0xFF5E132A)),
                                ),
                              ),
                              if (_pinMode && _storedCompanyId.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _clearStoredCompanyId(),
                                  icon: Icon(Icons.link_off,
                                      size: 14, color: Colors.grey),
                                  label: Text("Re-enroll device",
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.grey)),
                                ),
                              Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final asyncPkg =
                                          ref.watch(appPackageInfoProvider);
                                      return asyncPkg.when(
                                        data: (pkg) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text('v${pkg.version}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[700])),
                                        ),
                                        loading: () => SizedBox.shrink(),
                                        error: (_, __) => SizedBox.shrink(),
                                      );
                                    },
                                  ),
                                  if (!_pinMode)
                                    Row(
                                      children: [
                                        _buildActionButton(
                                          "Cancel",
                                          Colors.grey[200]!,
                                          Colors.black87,
                                          Icons.close,
                                          () => Navigator.of(context).pop(),
                                        ),
                                        SizedBox(width: 16),
                                        _buildActionButton(
                                          "Login",
                                          Color(0xFF2C3E50),
                                          Colors.white,
                                          Icons.login,
                                          () => _handleLogin(context),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF5E132A), // Changed to match theme
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "MOIF TECHNOLOGY",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 40),
                            if (!(_pinMode && _selectedStaff == null))
                              _buildNumericKeypad(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          "Username",
          usernameController,
          Icons.person_outline,
          false,
          focusNode: usernameFocusNode,
        ),
        SizedBox(height: 24),
        _buildTextField(
          "Password",
          passwordController,
          Icons.lock_outline,
          !_isPasswordVisible,
          focusNode: passwordFocusNode,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        SizedBox(height: 24),
        _buildDatabaseSelector(),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool obscureText, {
    Widget? suffixIcon,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: focusNode?.hasFocus == true
                  ? Color(0xFF5E132A)
                  : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            style: GoogleFonts.poppins(),
            onSubmitted: (value) {
              if (focusNode == usernameFocusNode) {
                if (value.isEmpty) {
                  setState(() {
                    _errorMessage = "Please enter username";
                  });
                } else {
                  passwordFocusNode.requestFocus();
                }
              } else if (focusNode == passwordFocusNode) {
                if (usernameController.text.isEmpty) {
                  setState(() {
                    _errorMessage = "Please enter username";
                  });
                  usernameFocusNode.requestFocus();
                } else if (value.isEmpty) {
                  setState(() {
                    _errorMessage = "Please enter password";
                  });
                } else {
                  _handleLogin(context);
                }
              }
            },
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFF5E132A)),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Database",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: databaseValue,
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 20),
              borderRadius: BorderRadius.circular(15),
              items: ["SERVER", "LOCAL"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  databaseValue = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffPicker() {
    if (_loadingStaff) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5E132A)));
    }
    if (_staffList.isEmpty) {
      return Center(
        child: Text(
          'No staff with PIN set.\nAssign PINs in backoffice first.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: _staffList.length,
      itemBuilder: (_, i) {
        final s = _staffList[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            _selectedStaff = s;
            _pin = '';
            _errorMessage = null;
          }),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5E132A).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF5E132A).withValues(alpha: 0.25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s['staffName']?.toString() ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (s['roleName'] != null)
                  Text(
                    s['roleName'].toString(),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Color(0xFF5E132A) : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildNumericKeypad() {
    final rows = _pinMode
        ? [
            ["7", "8", "9"],
            ["4", "5", "6"],
            ["1", "2", "3"],
            ["C", "0", "⌫"]
          ]
        : [
            ["7", "8", "9"],
            ["4", "5", "6"],
            ["1", "2", "3"],
            ["0", ".", "C"]
          ];
    return Column(
      children: [
        for (var row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) => _buildKeypadButton(key)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildKeypadButton(String value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_pinMode) {
            setState(() {
              if (value == "C") {
                _pin = '';
                _errorMessage = null;
              } else if (value == "⌫") {
                if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
              } else if (_pin.length < 4) {
                _pin = _pin + value;
              }
            });
            if (_pin.length == 4) {
              Future.microtask(_handlePinLogin);
            }
            return;
          }
          setState(() {
            if (focusedController == null) {
              usernameFocusNode.requestFocus();
              focusedController = usernameController;
              return;
            }

            if (value == "C") {
              focusedController?.clear();
            } else {
              String currentText = focusedController?.text ?? "";
              if (value == "." && currentText.contains(".")) {
                return;
              }
              focusedController?.text = currentText + value;
            }
          });
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    Color textColor,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final isLoginButton = label == "Login";
    final isLoading = isLoginButton && _isLoading;
    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              if (isLoginButton) {
                if (usernameController.text.isEmpty) {
                  setState(() {
                    _errorMessage = "Please enter username";
                  });
                  usernameFocusNode.requestFocus();
                } else if (passwordController.text.isEmpty) {
                  setState(() {
                    _errorMessage = "Please enter password";
                  });
                  passwordFocusNode.requestFocus();
                } else {
                  onPressed();
                }
              } else {
                onPressed();
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isLoginButton ? Color(0xFF5E132A) : color,
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }
}

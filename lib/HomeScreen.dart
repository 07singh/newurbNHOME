import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '/emoloyee_file/profile_screenforemployee.dart';
import 'DirectLogin/add_visitorem.dart' show AddVisitorScreenem;
import 'EmployeeDashboard/attendanceHistory.dart';
import 'EmployeeDashboard/attendance_router.dart';
import 'EmployeeDashboard/staff_attendance_screen.dart';
import 'add_header_page.dart';
import '/sign_page.dart';
import '/DirectLogin/add_visitor_screen.dart';
import '/DirectLogin/addVisitorlistforem.dart';
import 'today_flowup_page.dart';
import 'week_flowup_page.dart';
import '/service/auth_manager.dart';
import '/service/attendance_manager.dart';
import '/service/banner_service.dart';
import '/service/attendancerecordService.dart';
import '/Model/banner_model.dart';
import '/Model/AttendanceRecord.dart';
import '/Employ.dart';
import'/ChangePasswordScreenem.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;
  final String? userRole;
  final String? profileImageUrl;
  final String? userPhone;

  const HomeScreen({
    super.key,
    this.userName,
    this.userRole,
    this.profileImageUrl,
    this.userPhone,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _bannerImageUrls = [];
  final BannerService _bannerService = BannerService();
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoadingBanners = true;
  bool _isFetchingBanners = false;

  int _currentIndex = 0;
  bool _isRefreshing = false;
  late Timer _timer;
  Timer? _bannerRefreshTimer;
  final PageController _pageController = PageController();
  final _storage = const FlutterSecureStorage();
  String? _userName;
  String? _userRole;
  String? _profileImageUrl;
  String? _userPhone;

  // Attendance summary (per employee, per month)
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoadingAttendanceSummary = false;
  String? _attendanceSummaryError;
  int _totalDaysInMonth = 0;
  int _presentDays = 0;
  int _absentDays = 0;
  int _leaveDays = 0;
  List<AttendanceRecord> _allAttendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBanners();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _bannerImageUrls.isNotEmpty && !_isLoadingBanners) {
        if (_currentIndex < _bannerImageUrls.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        }
      }
    });
    _bannerRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isFetchingBanners) {
        _loadBanners(showLoader: false);
      }
    });
  }

  Future<void> _loadBanners({bool showLoader = true}) async {
    if (_isFetchingBanners) return;

    setState(() {
      _isFetchingBanners = true;
      if (showLoader) {
        _isLoadingBanners = true;
      }
    });

    try {
      final response = await _bannerService.getBannerImages();
      print('Banner response received: ${response != null}');
      
      if (response != null && response.banners.isNotEmpty) {
        List<String> imageUrls = [];

        // Helper to normalize urls
        String? _normalizeImageUrl(String? imagePath) {
          if (imagePath == null || imagePath.isEmpty || imagePath.toLowerCase() == 'null') {
            return null;
          }
          final trimmed = imagePath.trim();
          if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
            return trimmed;
          }
          if (trimmed.startsWith('/')) {
            return 'https://realapp.cheenu.in$trimmed';
          }
          return 'https://realapp.cheenu.in/$trimmed';
        }

        // Sort banners so the newest (highest ID) appears first
        final sortedBanners = [...response.banners]
          ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

        for (final banner in sortedBanners) {
          if (imageUrls.length >= 3) break;
          print('Processing banner ID: ${banner.id}');
          final candidates = [
            _normalizeImageUrl(banner.image1),
            _normalizeImageUrl(banner.image2),
            _normalizeImageUrl(banner.image3),
          ];
          for (final url in candidates) {
            if (url != null && url.isNotEmpty) {
              imageUrls.add(url);
              if (imageUrls.length >= 3) break;
            }
          }
        }

        print('Total latest image URLs collected: ${imageUrls.length}');
        setState(() {
          _bannerImageUrls
            ..clear()
            ..addAll(imageUrls);
          _isLoadingBanners = false;
          _currentIndex = 0;
          if (_bannerImageUrls.isEmpty) {
            print('No banner images found after parsing, using fallback');
            _bannerImageUrls.addAll([
              'assets/imglogo9.png',
              'assets/imglogo8.png',
              'assets/imglogo7.png',
            ]);
          }
          if (_pageController.hasClients && _bannerImageUrls.isNotEmpty) {
            _pageController.jumpToPage(0);
          }
        });
      } else {
        print('No banners in response, using fallback');
        setState(() {
          _isLoadingBanners = false;
          _currentIndex = 0;
          // Fallback to default images if API fails
          _bannerImageUrls.clear();
          _bannerImageUrls.addAll([
            'assets/imglogo9.png',
            'assets/imglogo8.png',
            'assets/imglogo7.png',
          ]);
          if (_pageController.hasClients && _bannerImageUrls.isNotEmpty) {
            _pageController.jumpToPage(0);
          }
        });
      }
    } catch (e) {
      print('Error loading banners: $e');
      setState(() {
        _isLoadingBanners = false;
        _currentIndex = 0;
        _bannerImageUrls.clear();
        _bannerImageUrls.addAll([
          'assets/imglogo9.png',
          'assets/imglogo8.png',
          'assets/imglogo7.png',
        ]);
        if (_pageController.hasClients && _bannerImageUrls.isNotEmpty) {
          _pageController.jumpToPage(0);
        }
      });
    }
    setState(() {
      _isFetchingBanners = false;
      if (!showLoader) {
        _isLoadingBanners = false;
      }
    });
  }

  Future<void> _loadUserData() async {
    String? name = await _storage.read(key: 'user_name');
    String? role = await _storage.read(key: 'user_role');
    String? phone = await _storage.read(key: 'user_mobile');
    String? imageUrl = await _storage.read(key: 'profile_image_url');
    setState(() {
      _userName = name ?? widget.userName ?? phone ?? 'User';
      _userRole = role ?? widget.userRole ?? 'Employee';
      _userPhone = phone ?? widget.userPhone ?? '';
      _profileImageUrl = imageUrl ?? widget.profileImageUrl;
    });

    // After we know the user's phone, load their monthly attendance summary
    if (_userPhone != null && _userPhone!.isNotEmpty) {
      await _loadAttendanceSummary();
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadUserData();
    await _loadBanners();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadAttendanceSummary() async {
    if (_userPhone == null || _userPhone!.isEmpty) return;

    setState(() {
      _isLoadingAttendanceSummary = true;
      _attendanceSummaryError = null;
    });

    try {
      final response = await _attendanceService.getAttendanceRecords();
      _allAttendanceRecords = response.data;

      _recalculateAttendanceSummary();
    } catch (e) {
      setState(() {
        _attendanceSummaryError = 'Unable to load attendance summary';
        _totalDaysInMonth = 0;
        _presentDays = 0;
        _absentDays = 0;
        _leaveDays = 0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAttendanceSummary = false;
        });
      }
    }
  }

  void _recalculateAttendanceSummary() {
    if (_userPhone == null || _userPhone!.isEmpty) return;

    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    // Filter records for this employee and selected month
    final recordsForUserAndMonth = _allAttendanceRecords.where((record) {
      return record.empMob == _userPhone &&
          record.createDate.year == year &&
          record.createDate.month == month;
    }).toList();

    // Use sets of days so multiple records per day count once
    final Set<DateTime> presentDays = {};
    final Set<DateTime> absentDays = {};
    final Set<DateTime> leaveDays = {};

    DateTime _dayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    for (final record in recordsForUserAndMonth) {
      final day = _dayKey(record.createDate);
      final status = (record.status ?? '').toLowerCase();

      if (status.contains('leave')) {
        leaveDays.add(day);
      } else if (status.contains('absent')) {
        absentDays.add(day);
      } else {
        // Treat anything else as present
        presentDays.add(day);
      }
    }

    final totalDistinctDays =
        presentDays.union(absentDays).union(leaveDays).length;

    setState(() {
      _totalDaysInMonth = totalDistinctDays;
      _presentDays = presentDays.length;
      _absentDays = absentDays.length;
      _leaveDays = leaveDays.length;
    });
  }

  Future<void> _pickMonth() async {
    final initialDate = _selectedMonth;
    final firstDate = DateTime(initialDate.year - 1, 1);
    final lastDate = DateTime(initialDate.year + 1, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select month',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _recalculateAttendanceSummary();
    }
  }

  Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreenem (phone: _userPhone ?? ''),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _userName = result['name'] ?? _userName ?? 'User';
        _userRole = result['position'] ?? _userRole ?? 'Employee';
        // Update profile image if a new value is provided
        if (result['profileImageUrl'] != null && result['profileImageUrl'].toString().isNotEmpty) {
          _profileImageUrl = result['profileImageUrl'];
        }
        _userPhone = result['phone'] ?? _userPhone ?? '';
      });
      await _storage.write(key: 'user_name', value: _userName);
      await _storage.write(key: 'user_role', value: _userRole);
      if (_profileImageUrl != null) {
        await _storage.write(key: 'profile_image_url', value: _profileImageUrl);
      }
      if (_userPhone != null) {
        await _storage.write(key: 'user_mobile', value: _userPhone);
      }
      // Force rebuild to update drawer image
      setState(() {});
    }
  }

  void _openChangePasswordScreenem() {
    if (_userPhone == null || _userPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreenem(
          phone: _userPhone!,
          position: _userRole ?? 'Employee',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _bannerRefreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 165, // Reduced height to prevent overflow
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: _profileImageUrl!,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          placeholder: (context, url) => Container(
                            color: Colors.white.withOpacity(0.2),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : const Icon(Icons.person, size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hello, ${_userName ?? "User"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15, // Slightly smaller font
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 1. Dashboard
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.deepPurple),
              title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // 2. Profile
            ListTile(
              leading: const Icon(Icons.person, color: Colors.teal),
              title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _navigateToProfile();
              },
            ),
            // 3. Attendance
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AttendanceRouter()),
                );
              },
            ),
            // 4. Attendance Record
            ListTile(
              leading: const Icon(Icons.fact_check, color: Colors.green),
              title: const Text('Attendance Record', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                if (_userPhone != null && _userPhone!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StaffAttendanceScreen(phone: _userPhone!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number not available'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            // 5. Setting
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: _openChangePasswordScreenem,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red.shade600),
              title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                // Clear Hive session
                await AuthManager.clearSession();
                // Clear attendance state
                await AttendanceManager.clearCheckIn();
                // Also clear secure storage for backward compatibility
                await _storage.deleteAll();

                // Navigate to role selection screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "Employee Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _handleRefresh,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Carousel
            SizedBox(
              height: 150,
              child: _isLoadingBanners
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Loading banners...'),
                        ],
                      ),
                    )
                  : _bannerImageUrls.isEmpty
                      ? Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[300],
                          ),
                          child: const Center(
                            child: Text('No banners available'),
                          ),
                        )
                      : Stack(
                          children: [
                            PageView.builder(
                          key: ValueKey('banner_${_bannerImageUrls.length}'),
                controller: _pageController,
                          itemCount: _bannerImageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                itemBuilder: (context, index) {
                            String imageUrl = _bannerImageUrls[index];
                            bool isNetworkImage = imageUrl.startsWith('http');
                            
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: isNetworkImage
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        headers: {
                                          'Accept': 'image/*',
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ Error loading network image: $imageUrl');
                                          print('Error type: ${error.runtimeType}');
                                          print('Error details: $error');
                                          if (error is Exception) {
                                            print('Exception: ${error.toString()}');
                                          }
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Failed to load image',
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                                const SizedBox(height: 4),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text(
                                                    imageUrl,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 10,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        imageUrl,
                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading asset image: $imageUrl - $error');
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Failed to load image',
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                      ),
                    ),
                  );
                },
                            ),
                            // Debug indicator (remove in production)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_currentIndex + 1}/${_bannerImageUrls.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
              ),
            ),
            const SizedBox(height: 20),

            // Welcome Section
            Text(
              'Welcome, ${_userName ?? "User"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Your role: ${_userRole ?? "Employee"}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFlowUpButton(
                    context,
                    "Add Follow-up",
                    Icons.add_task_rounded,
                    Colors.deepPurple,
                    LinearGradient(colors: [Colors.deepPurple, Colors.purple]),
                    TodayFollowupFormPage(),
                  ),
                  const SizedBox(width: 12),
                  _buildFlowUpButton(
                    context,
                    "View Follow-up",
                    Icons.visibility_rounded,
                    Colors.blue,
                    LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
                    WeekFlowupPage(),
                  ),
                  const SizedBox(width: 12),
                  _buildFlowUpButton(
                    context,
                    "View Visitor List",
                    Icons.list_alt_rounded,
                    Colors.green,
                    LinearGradient(colors: [Colors.green, Colors.lightGreen]),
                    VisitorListScreenem(),
                  ),
                  const SizedBox(width: 12),
                  _buildFlowUpButton(
                    context,
                    "Add Visitor",
                    Icons.add_box_rounded,
                    Colors.orange,
                    LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                    AddVisitorScreenem(),
                    onAfterPop: () async {
                      await _loadUserData();
                      await _loadBanners(showLoader: false);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attendance Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickMonth,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    DateFormat('MMM yyyy').format(_selectedMonth),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            if (_isLoadingAttendanceSummary)
              const LinearProgressIndicator(minHeight: 3),
            if (_attendanceSummaryError != null) ...[
              const SizedBox(height: 8),
              Text(
                _attendanceSummaryError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5, // Adjusted to prevent overflow
              children: [
                _buildSummaryCard('Total Days', _totalDaysInMonth.toString(), Colors.deepPurple),
                _buildSummaryCard('Present', _presentDays.toString(), Colors.green),
                _buildSummaryCard('Absent', _absentDays.toString(), Colors.red),
                _buildSummaryCard('Leave', _leaveDays.toString(), Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowUpButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      Gradient gradient,
      Widget page,
      {Future<void> Function()? onAfterPop}) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
              if (onAfterPop != null && mounted) {
                await onAfterPop();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
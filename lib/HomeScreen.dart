import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/emoloyee_file/profile_screenforemployee.dart';
import 'DirectLogin/add_visitorem.dart' show AddVisitorScreenem;
import 'EmployeeDashboard/attendanceHistory.dart';
import 'EmployeeDashboard/attendance_router.dart';
import 'EmployeeDashboard/staff_attendance_screen.dart';
import 'today_flowup_page.dart';
import 'week_flowup_page.dart';
import 'total_flowup_page.dart';
import 'add_header_page.dart';
import '/sign_page.dart';
import'/DirectLogin/add_visitor_screen.dart';
import'/DirectLogin/addVisitorlistforem.dart';
import '/service/auth_manager.dart';
import '/service/attendance_manager.dart';
import '/Employ.dart';

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
  final List<String> _imageList = [
    'assets/imglogo9.png',
    'assets/imglogo8.png',
    'assets/imglogo7.png',
  ];

  int _currentIndex = 0;
  late Timer _timer;
  final PageController _pageController = PageController();
  final _storage = const FlutterSecureStorage();
  String? _userName;
  String? _userRole;
  String? _profileImageUrl;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentIndex < _imageList.length - 1) {
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
  }

  Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreenem (phone: _userPhone ?? ''),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        _userName = result['name'] ?? _userName ?? 'User';
        _userRole = result['position'] ?? _userRole ?? 'Employee';
        _profileImageUrl = result['profileImageUrl'];
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
    }
  }

  @override
  void dispose() {
    _timer.cancel();
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
                      radius: 25, // Slightly smaller avatar
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? ClipOval(
                        child: Image.network(
                          _profileImageUrl!,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) => const Icon(
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
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.deepPurple),
              title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
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
            ListTile(
              leading: const Icon(Icons.person, color: Colors.teal),
              title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _navigateToProfile();
              },
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
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Carousel
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _imageList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage(_imageList[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
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
                    "Today's Follow-up",
                    Icons.today_rounded,
                    Colors.deepPurple,
                    LinearGradient(colors: [Colors.deepPurple, Colors.purple]),
                    TodayFlowupPage(),
                  ),
                  const SizedBox(width: 12),
                  _buildFlowUpButton(
                    context,
                    "This Week Follow-up",
                    Icons.calendar_view_week_rounded,
                    Colors.blue,
                    LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
                    WeekFlowupPage(),
                  ),
                  const SizedBox(width: 12),
                  _buildFlowUpButton(
                    context,
                    "Add Visitor list",
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attendance Summary
            Text(
              'Attendance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5, // Adjusted to prevent overflow
              children: [
                _buildSummaryCard('Total Days', '22', Colors.deepPurple),
                _buildSummaryCard('Present', '20', Colors.green),
                _buildSummaryCard('Absent', '2', Colors.red),
                _buildSummaryCard('Leave', '1', Colors.orange),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            _navigateToProfile();
          } else if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reports clicked')),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
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
      ) {
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
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
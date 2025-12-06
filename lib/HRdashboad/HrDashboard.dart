import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../DirectLogin/add_staff_hr.dart';
import '../DirectLogin/add_staff_listhr.dart';
import '../EmployeeDashboard/historyforHr.dart';
import '../emoloyee_file/bookingRequestForHr.dart';
import '../emoloyee_file/profile_screenforhr.dart';
import '/emoloyee_file/profile_screen.dart';
import '/emoloyee_file/booking_request.dart';
import '/HRdashboad/Add_employee.dart';
import '/HRdashboad/sehedule_interview_screen.dart';
import '/HRdashboad/levee_request_screen.dart';
import '/HRdashboad/report_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/plot_screen/hrplot.dart';
import'/DirectLogin/add_visitor_list_screen.dart';
import'/DirectLogin/add_staff_screen.dart';
import'/DirectLogin/add_staff.dart';
import '/service/auth_manager.dart';
import '/service/attendance_manager.dart';
import '/service/profile_service.dart';
import '/Model/profile_model.dart';
import '/screens/banner_management_screen.dart';
import '/Employ.dart';
import 'HrAddNotifation.dart';
import 'PaymentHistoryScreen.dart';
import'/ChangePasswordScreenhr.dart';
import '/DirectLogin/add_day_bookhr.dart';
import '/DirectLogin/add_day_history_screenhr.dart';
import '/DirectLogin/add_detail_screenhr.dart';

class HRDashboardPage extends StatefulWidget {
  final String userName;
  final String userRole;
  final String? profileImageUrl;

  const HRDashboardPage({
    Key? key,
    required this.userName,
    required this.userRole,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  _HRDashboardPageState createState() => _HRDashboardPageState();
}

class _HRDashboardPageState extends State<HRDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  final StaffProfileService _profileService = StaffProfileService();
  String? _userPhone;
  String? _profileImageUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserPhone(); // This will also trigger _loadProfileImage()
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    try {
      String? phone = _userPhone ?? await storage.read(key: 'user_mobile');
      if (phone == null || phone.isEmpty) {
        final session = await AuthManager.getCurrentSession();
        phone = session?.userMobile ?? session?.phone;
      }
      
      if (phone != null && phone.isNotEmpty) {
        final response = await _profileService.fetchProfile(
          phone: phone,
          position: widget.userRole,
        );
        
        if (response.staff != null && mounted) {
          setState(() {
            _profileImageUrl = response.staff!.fullProfilePicUrl;
            _isLoadingProfile = false;
          });
        } else {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>   ProfileScreenhr ()),
    );
    if (result != null && result is Map<String, String>) {
      // Reload profile image when returning from profile screen
      _loadProfileImage();
    } else {
      // Even if no result, reload to get updated image
      _loadProfileImage();
    }
  }
  Future<void> _loadUserPhone() async {
    String? phone = await storage.read(key: 'user_mobile');
    if (phone == null || phone.isEmpty) {
      final session = await AuthManager.getCurrentSession();
      phone = session?.userMobile ?? session?.phone;
    }
    if (!mounted) return;
    setState(() {
      _userPhone = phone;
    });
    // Load profile image after phone is available
    if (phone != null && phone.isNotEmpty) {
      _loadProfileImage();
    }
  }

  void _navigateToChangePasswordScreenhr() {
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
        builder: (context) => ChangePasswordScreenhr(
          phone: _userPhone!,
          position: widget.userRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "HR Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none, size: 26),
              onPressed: () {
                // Navigate to Notification Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddHrNotificationPage()),
                );
              }
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildStatsOverview(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentActivities(),
          ],
        ),
      ),

    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header - Smart Profile Image
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade800, Colors.blue.shade600],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildProfileAvatar(80),
                  const SizedBox(height: 12),
                  Text(
                    widget.userName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userRole,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),

            _buildDrawerSectionHeader("MAIN"),
            _buildDrawerItem(
              icon: Icons.dashboard_rounded,
              title: "Dashboard",
              isSelected: true,
              onTap: () => Navigator.pop(context),
            ),

            _buildDrawerSectionHeader("EMPLOYEE MANAGEMENT"),
            // UPDATED: Employee Management navigation items
            _buildExpandableDrawerItem(
              icon: Icons.people_alt_rounded,
              title: "Employee Management",
              children: [
                // Add Employee -> AddStaffScreen
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ListTile(
                    leading: Icon(Icons.person_add_alt_1_rounded, color: Colors.grey.shade500, size: 18),
                    title: Text("Add Employee", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) =>  AddStaffScreenhr ()));
                    },
                  ),
                ),

                // View Employee -> StaffListScreen
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ListTile(
                    leading: Icon(Icons.person_search_rounded, color: Colors.grey.shade500, size: 18),
                    title: Text("View Employee", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) =>  StaffListScreenhr ()));
                    },
                  ),
                ),

                // Attendance Regular -> AttendanceScreentHr
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ListTile(
                    leading: Icon(Icons.calendar_today_rounded, color: Colors.grey.shade500, size: 18),
                    title: Text("Attendance Regular", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreentHr()));
                    },
                  ),
                ),

                // Attendance Repeat (unchanged)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ListTile(
                    leading: Icon(Icons.repeat_rounded, color: Colors.grey.shade500, size: 18),
                    title: Text("Attendance Repeat", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar(context, "Selected: Attendance Repeat");
                    },
                  ),
                ),
              ],
            ),



            // UPDATED: Plot Management with 2 options
            _buildDrawerSectionHeader("PLOT MANAGEMENT"),
            _buildExpandableDrawerItem(
              icon: Icons.landscape_rounded,
              title: "Plot Management",
              children: [
                // Booking Request
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ListTile(
                    leading: Icon(Icons.list_alt_rounded, color: Colors.grey.shade500, size: 18),
                    title: Text("Booking Request", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) =>PendingRequestsHrScreen(userRole: widget.userRole)));
                    },
                  ),
                ),

                // Book Now -> NoNav() (book plot)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ListTile(
                    leading: Icon(Icons.add_business_rounded, color: Colors.grey.shade500, size: 18),
                    title: Text("Book Now", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NoNav()));
                    },
                  ),
                ),
              ],
            ),

            _buildDrawerSectionHeader("SETTINGS"),
            _buildDrawerItem(
              icon: Icons.settings_rounded,
              title: "Settings",
              onTap: () {
                Navigator.pop(context);  // Drawer close
                _navigateToChangePasswordScreenhr(); // Navigate to screen
              },
            ),

            _buildDrawerItem(
              icon: Icons.person_rounded,
              title: "My Profile",
              onTap: () {
                Navigator.pop(context);
                _navigateToProfile();
              },
            ),

            _buildDrawerSectionHeader("BANNER MANAGEMENT"),
            _buildDrawerItem(
              icon: Icons.image_rounded,
              title: "Banner Management",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BannerManagementScreen(),
                  ),
                );
              },
            ),

            _buildDrawerSectionHeader("DAY BOOK"),
            _buildDrawerItem(
              icon: Icons.book_rounded,
              title: "Add Day Book",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddDayBookScreenhr(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.history_rounded,
              title: "Day Book History",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DayBookHistoryScreenhr(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red.shade600),
                  title: Text("Logout", style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 300), () => _showLogoutConfirmation(context));
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.shade200, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${widget.userName}!",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Here's your ${widget.userRole} dashboard overview for today",
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Smart Profile Image in Dashboard
          _buildProfileAvatar(80),
        ],
      ),
    );
  }

  // === ALL OTHER WIDGETS UNCHANGED BELOW ===
  Widget _buildDrawerSectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
  );

  Widget _buildDrawerItem({required IconData icon, required String title, bool isSelected = false, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.blue.shade100) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600, size: 22),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 14)),
        trailing: isSelected ? Icon(Icons.circle, color: Colors.blue.shade700, size: 8) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildExpandableDrawerItem({required IconData icon, required String title, required List<Widget> children}) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.grey.shade600, size: 22),
      title: Text(title, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 14)),
      children: children,
    );
  }

  Widget _buildSubMenuItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade500, size: 18),
        title: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        onTap: () {
          Navigator.pop(context);
          _showSnackBar(context, "Selected: $title");
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
  }

  // Add these two variables at the top of the class:
  int pendingBookingCount = 0;
  int paymentHistoryCount = 0;

// Then use this updated widget
  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Overview",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            // UPDATED: Card 1 -> Booking Request (Dynamic)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PendingRequestsHrScreen(userRole: widget.userRole),
                  ),
                );
              },
              child: _buildStatCard(
                title: "Booking Request",
                value: pendingBookingCount.toString(), // DYNAMIC VALUE
                icon: Icons.list_alt_rounded,
                color: Colors.blue,
                change: "Tap to view",
              ),
            ),

            // UPDATED: Card 2 -> Payment History (Dynamic)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentHistoryScreen()),
                );
              },
              child: _buildStatCard(
                title: "Payment History",
                value: paymentHistoryCount.toString(), // DYNAMIC VALUE
                icon: Icons.payment_rounded,
                color: Colors.orange,
                change: "Tap to view",
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color, required String change}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(change, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // UPDATED: 1 -> Attendance Record
              _buildActionButton("Attendance Record", Icons.calendar_today_rounded, Colors.blue, AttendanceScreentHr()),
              const SizedBox(width: 12),

              // UPDATED: 2 -> Staff List
              _buildActionButton("Staff List", Icons.people_alt_rounded, Colors.green, StaffListScreenhr()),
              const SizedBox(width: 12),

              // Rest unchanged
              _buildActionButton("booking Now", Icons.calendar_today_rounded, Colors.purple, NoNav()),
              const SizedBox(width: 12),
              _buildActionButton("Visitor list", Icons.analytics_rounded, Colors.red, VisitorListScreen ()),
              const SizedBox(width: 12),
              _buildActionButton("Add Day Book", Icons.book_rounded, Colors.teal, const AddDayBookScreenhr()),
              const SizedBox(width: 12),
              _buildActionButton("Day Book History", Icons.history_rounded, Colors.indigo, const DayBookHistoryScreenhr()),

            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Recent Activities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            TextButton(onPressed: () {}, child: Text("View All", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildActivityItem("John Doe submitted leave request", "2 hours ago", Icons.beach_access_rounded, Colors.orange),
              _buildActivityItem("New hire: Jane Smith - Marketing", "5 hours ago", Icons.person_add_alt_1_rounded, Colors.green),
              _buildActivityItem("Payroll processed for March", "1 day ago", Icons.payment_rounded, Colors.blue),
              _buildActivityItem("Performance review scheduled", "2 days ago", Icons.calendar_today_rounded, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }



  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [Icon(Icons.logout_rounded, color: Colors.red.shade600), const SizedBox(width: 8), const Text("Logout")]),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context) async {
    // Clear Hive session
    await AuthManager.clearSession();
    // Clear attendance state
    await AttendanceManager.clearCheckIn();

    // Clear secure storage
    await storage.deleteAll();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text("Logged out successfully"), backgroundColor: Colors.green.shade600, duration: const Duration(seconds: 2)),
    );

    // Navigate to Employ.dart (main role selection screen)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
    );
  }

  Widget _buildProfileAvatar(double size) {
    if (_isLoadingProfile) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.white.withOpacity(0.3),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(
        child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
            ? Image.network(
                _profileImageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white.withOpacity(0.3),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white.withOpacity(0.3),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.white.withOpacity(0.3),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
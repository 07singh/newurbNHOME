import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/plot_screen/book_plot.dart';
import '/Add_associate/add_associate_screen.dart';
import '/emoloyee_file/profile_screen.dart';
import '/Add_associate/add_associate_list_screen.dart';
import '/emoloyee_file/attendence_record.dart';
import '/DirectLogin/add_day_book.dart';
import '/DirectLogin/client_visit.dart';
import '/DirectLogin/add_day_history_screen.dart';
import '/emoloyee_file/booking_request.dart';
import '/Employ.dart';
import '/provider/user_provider.dart';
import'/DirectLogin/add_staff.dart';
import'/DirectLogin/add_staff_screen.dart';
import'/DirectLogin/add_visitor_list_screen.dart';
import '/service/auth_manager.dart';
import '/service/attendance_manager.dart';
import '/service/profile_service.dart';
import '/Model/profile_model.dart';
import '/EmployeeDashboard/attendanceHistory.dart';
import'/changepassword.dart';

class DirectloginPage extends StatefulWidget {
  final String? userName; // ✅ Added
  final String? userRole; // ✅ Added
  final String? profileImageUrl;

  const DirectloginPage({
    Key? key,
    this.userName,
    this.userRole,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  _DirectloginPageState createState() => _DirectloginPageState();
}
class _DirectloginPageState extends State<DirectloginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Profile data from API
  Staff? _profile;
  bool _isLoadingProfile = true;
  String? _profileError;
  
  // Services
  final StaffProfileService _profileService = StaffProfileService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Fetches profile data from API and updates UI + Session
  Future<void> _loadProfileData() async {
    try {
      // Get phone and position from storage or session
      String? phone = await _storage.read(key: 'user_mobile');
      String? position = widget.userRole ?? await _storage.read(key: 'user_role');
      
      // Fallback to session if not in storage
      if (phone == null || phone.isEmpty) {
        final session = await AuthManager.getCurrentSession();
        phone = session?.userMobile ?? session?.phone;
        position = session?.userRole ?? session?.position;
      }
      
      if (phone == null || phone.isEmpty) {
        setState(() {
          _isLoadingProfile = false;
          _profileError = 'Phone number not available';
        });
        return;
      }
      
      print('🌐 Loading Director profile: Phone=$phone, Position=$position');
      
      // Fetch profile from API
      final response = await _profileService.fetchProfile(
        phone: phone,
        position: position ?? 'Director',
      );
      
      if (response.staff != null && mounted) {
        setState(() {
          _profile = response.staff;
          _isLoadingProfile = false;
          _profileError = null;
        });
        
        print('✅ Profile loaded: ${_profile!.fullName}');
        print('📸 Image URL: ${_profile!.fullProfilePicUrl}');
        
        // Update session with real profile data
        await AuthManager.updateSession(
          userName: _profile!.fullName,
          profilePic: _profile!.profilePicUrl,
          userRole: _profile!.position,
        );
      } else {
        setState(() {
          _isLoadingProfile = false;
          _profileError = 'Profile not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _profileError = 'Failed to load profile: $e';
        });
        print('❌ Error loading profile: $e');
      }
    }
  }
  
  /// Refresh profile data
  Future<void> _refreshProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });
    await _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // ✅ Give priority: API profile → widget props → provider → defaults
    final userName = _profile?.fullName ?? widget.userName ?? userProvider.name ?? 'User';
    final userRole = _profile?.position ?? widget.userRole ?? userProvider.role ?? 'Director';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(userRole),
      drawer: _buildDrawer(userName, userRole),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner if profile failed to load
            if (_buildErrorBanner() != null) _buildErrorBanner()!,
            
            _buildWelcomeSection(userName),
            const SizedBox(height: 24),
            _buildStatsOverview(userRole),
            const SizedBox(height: 24),
            _buildQuickActions(userRole),
            const SizedBox(height: 24),
            _buildRecentActivities(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ------------------ APPBAR ------------------
  AppBar _buildAppBar(String userRole) {
    return AppBar(
      title: Text(
        "$userRole Dashboard",
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFFFD700),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 26),
          onPressed: _refreshProfile,
          tooltip: 'Refresh Profile',
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 26),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ------------------ DRAWER ------------------
  Widget _buildDrawer(String userName, String userRole) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(userName, userRole),
            _buildDrawerSection("MAIN"),
            _buildDrawerItem(
              icon: Icons.dashboard_rounded,
              title: "Main Dashboard",
              isSelected: true,
              onTap: () {},
            ),
            if (userRole == "Director" || userRole == "Admin") ...[
              _buildDrawerSection("PLOT MANAGEMENT"),
              _buildDrawerItem(
                icon: Icons.map_rounded,
                title: "My Profile",
                onTap: () => _navigateTo(const ProfileScreen()),
              ),
              _buildDrawerItem(
                icon: Icons.check_circle_rounded,
                title: "Booking Request",
                onTap: () => _navigateTo(PendingRequestsScreen(userRole: userRole)),

              ),
              _buildDrawerItem(
                icon: Icons.bookmark_rounded,
                title: "Book Plot",
                onTap: () => _navigateTo(const BookPlotScreen()),
              ),
              _buildDrawerSection("ASSOCIATE MANAGEMENT"),
              _buildDrawerItem(
                icon: Icons.person_add_rounded,
                title: "Add Associate",
                onTap: () => _navigateTo(const AddAssociateScreen()),
              ),
              _buildDrawerItem(
                icon: Icons.list_alt_rounded,
                title: "Associate List",
                onTap: () => _navigateTo(const AssociateListScreen()),
              ),
            ],
            if (userRole == "Director") ...[
              _buildDrawerSection("DAY BOOKING"),
              _buildDrawerItem(
                icon: Icons.calendar_today_rounded,
                title: "Add Day Book",
                onTap: () => _navigateTo(const AddDayBookScreen()),
              ),
              _buildDrawerItem(
                icon: Icons.book_online_rounded,
                title: "Day Booking Book",
                onTap: () => _navigateTo(const AddDayBookScreen()),
              ),
              _buildDrawerItem(
                icon: Icons.list_alt_rounded,
                title: "Day Book Details",
                onTap: () => _navigateTo(const DayBookHistoryScreen()),
              ),
              _buildDrawerSection("VISITS"),
              _buildDrawerItem(
                icon: Icons.visibility_rounded,
                title: "Total Visits",
                onTap: () {},
              ),
              _buildDrawerItem(
                icon: Icons.today_rounded,
                title: "Add visitor list",
                onTap: () => _navigateTo(const VisitorListScreen ()),
              ),
              _buildDrawerItem(
                icon: Icons.today_rounded,
                title: "setting",
                onTap: () => _navigateTo(const ChangePasswordScreen()),
              ),
            ],
            if (userRole == "Associate") ...[
              _buildDrawerSection("MY BOOKINGS"),
              _buildDrawerItem(
                icon: Icons.bookmark_rounded,
                title: "My Bookings",
                onTap: () {},
              ),
            ],
            const SizedBox(height: 20),
            _buildLogoutTile(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String userName, String userRole) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFE082)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Profile Avatar with real image from API
          Stack(
            children: [
              _buildProfileAvatar(radius: 45),
              if (_profile != null && _profile!.status)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isLoadingProfile ? 'Loading...' : (_profile?.fullName ?? userName),
            style: const TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (_profile?.phone != null && _profile!.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _profile!.phone,
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _profile?.position ?? userRole,
            style: TextStyle(
              color: Colors.black.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_profile?.staffId != null && _profile!.staffId.isNotEmpty) ...[
            const SizedBox(height: 8),

          ],
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF8E1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: const Color(0xFFFFECB3)) : null,
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? const Color(0xFFFFD700) : Colors.grey.shade600,
            size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFD700) : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing:
        isSelected ? const Icon(Icons.circle, color: Color(0xFFFFD700), size: 8) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: ListTile(
          leading: Icon(Icons.logout_rounded, color: Colors.red.shade600),
          title: Text(
            "Logout",
            style: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Future.delayed(
                const Duration(milliseconds: 300),
                    () => _showLogoutConfirmation(context));
          },
        ),
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // ------------------ WELCOME ------------------
  Widget _buildWelcomeSection(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFE082)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0xFFFFECB3), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingProfile 
                      ? "Hello, Loading..."
                      : "Hello Mr. ${_profile?.fullName ?? userName}",
                  style: const TextStyle(
                      color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: const TextStyle(
                        color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Real profile image from API
          Stack(
            children: [
              _buildProfileAvatar(radius: 40),
              if (_profile != null && _profile!.status)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------ STATS & QUICK ACTIONS ------------------
  Widget _buildStatsOverview(String userRole) {
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
            if (userRole == "Director" || userRole == "Admin") ...[
              _buildStatCard(
                title: "Attendence Record",
                value: "",
                icon: Icons.map,
                color: Color(0xFFFFD700),
                change: " added this month",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceScreent(),
                    ),
                  );
                },
              ),
              _buildStatCard(
                title: "Booking Plot Now",
                value: "85",
                icon: Icons.event_available,
                color: Colors.green,
                change: "15 booked recently",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookPlotScreen(),
                    ),
                  );
                },
              ),
              _buildStatCard(
                title: "Booking Requests",
                value: "85",
                icon: Icons.home_work_rounded,
                color: Colors.green,
                change: "15 booked recently",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PendingRequestsScreen(
                        userRole: userRole, // ✅ pass role here
                      ),
                    ),
                  );

                },
              ),
              _buildStatCard(
                title: "Add Associate",
                value: "32",
                icon: Icons.person_add_alt_1_rounded,
                color: Colors.purple,
                change: " new associates",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddAssociateScreen(),
                    ),
                  );
                },
              ),
            ],
            if (userRole == "Director") ...[
              _buildStatCard(
                title: "Add Day Book",
                value: "12",
                icon: Icons.book_rounded,
                color: Colors.orange,
                change: "3 new entries today",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddDayBookScreen(),
                    ),
                  );
                },
              ),
              _buildStatCard(
                title: "Day Book Details",
                value: "58",
                icon: Icons.receipt_long,
                color: Colors.teal,
                change: "Updated recently",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DayBookHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
            if (userRole == "Associate") ...[
              _buildStatCard(
                title: "My Bookings",
                value: "10",
                icon: Icons.bookmark_rounded,
                color: Color(0xFFFFD700),
                change: "2 new bookings",
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ------------------ QUICK ACTIONS ------------------
  Widget _buildQuickActions(String userRole) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (userRole == "Director" || userRole == "Admin") ...[
                _buildActionButton(
                  "Add Staff",
                  Icons.person_add_alt_1_rounded,
                  Color(0xFFFFD700),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddStaffScreen()),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  "Associate List",
                  Icons.list_alt_rounded,
                  Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AssociateListScreen()),
                    );
                  },
                ),
                const SizedBox(width: 12),
              ],
              _buildActionButton(
                "Leave Requests",
                Icons.beach_access_rounded,
                Colors.orange,
              ),
              const SizedBox(width: 12),
              if (userRole == "Director") ...[
                _buildActionButton(
                  "Add staff list",
                  Icons.calendar_today_rounded,
                  Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StaffListScreen()),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  "Reports",
                  Icons.analytics_rounded,
                  Colors.red,
                ),
              ],
              if (userRole == "Associate") ...[
                _buildActionButton(
                  "My Bookings",
                  Icons.bookmark_rounded,
                  Color(0xFFFFD700),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ------------------ RECENT ACTIVITIES ------------------
  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activities",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(height: 0),
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFFFFD700)),
              title: Text("Activity #${index + 1}"),
              subtitle: Text("Details about activity #${index + 1}"),
            ),
          ),
        ),
      ],
    );
  }
  // ------------------ LOGOUT CONFIRMATION ------------------
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Clear Hive session
              await AuthManager.clearSession();
              // Clear attendance state
              await AttendanceManager.clearCheckIn();
              
              Navigator.pop(context); // Close dialog

              // ✅ Navigate to Employ.dart
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()), // 👈 your Employ screen
                    (route) => false, // Remove all previous routes
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ BOTTOM NAVIGATION ------------------
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFFD700),
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DirectloginPage()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookPlotScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClientVisitScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAssociateScreen ()),
            );
            break;
        }
      },
      selectedItemColor: Colors.black, // Black for contrast
      unselectedItemColor: Colors.grey.shade800, // Dark grey
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_rounded),
          label: "Bookings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.visibility_rounded),
          label: "Client Visit",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: "Add Associatate",
        ),
      ],
    );
  }
  
  // ------------------ PROFILE AVATAR BUILDER ------------------
  Widget _buildProfileAvatar({required double radius}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(
        child: _isLoadingProfile
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                ),
              )
            : _profile?.fullProfilePicUrl != null
                ? CachedNetworkImage(
                    imageUrl: _profile!.fullProfilePicUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print('❌ Image load error for $url: $error');
                      return Container(
                        color: Color(0xFFFFF8E1),
                        child: Icon(
                          Icons.person,
                          size: radius * 1.2,
                          color: Color(0xFFFFD700),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Color(0xFFFFF8E1),
                    child: Icon(
                      Icons.person,
                      size: radius * 1.2,
                      color: Color(0xFFFFD700),
                    ),
                  ),
      ),
    );
  }
  
  // ------------------ ERROR BANNER ------------------
  Widget? _buildErrorBanner() {
    if (_profileError != null && _profileError!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _profileError!,
                style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.orange.shade700, size: 20),
              onPressed: _refreshProfile,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }
    return null;
  }
}
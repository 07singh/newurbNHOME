import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '/Add_associate/associate_profile_screen.dart';
import '/signin_role/sign_role_associate.dart';
import '/plot_screen/book_plot.dart';
import '/asscoiate_plot_scren/book_plot.dart';
import '/screens/add_visit_screen.dart';           // NEW
import '/screens/payment.dart';         // NEW
import '/screens/total_commission_screen.dart';     // NEW
import '/screens/commission_received_screen.dart'; // NEW
import '/screens/MyBookingScreen.dart';
import '/service/auth_manager.dart';
import '/service/attendance_manager.dart';
import '/service/associate_profile_service.dart';
import '/service/service_of_indiviadual.dart';
import '/Model/associate_profile_model.dart';
import '/Model/modelofindividual.dart';
import'/screens/payment.dart';
import '/Employ.dart';
import 'asscoiate_plot_scren/associateDrawerHistory.dart';


// Fixed duplicate import
// import '/screens/commission_received_screen.dart'; // REMOVED

class AssociateDashboardPage extends StatefulWidget {
  final String userName;
  final String userRole;
  final String? profileImageUrl;
  final String phone;

  const AssociateDashboardPage({

    super.key,
    required this.userName,
    required this.userRole,
    this.profileImageUrl,
    required this.phone,
  });

  @override
  State<AssociateDashboardPage> createState() => _AssociateDashboardPageState();
}

class _AssociateDashboardPageState extends State<AssociateDashboardPage> {
  // User data - will be loaded from API
  late String _userName;
  late String _userRole;
  String? _profileImageUrl;
  String? _userEmail;
  String? _userPhone;
  String? _associateId;
  
  // Profile data from API
  AssociateProfile? _profile;
  bool _isLoadingProfile = true;
  String? _profileError;
  
  // Services
  final AssociateProfileService _profileService = AssociateProfileService();
  final BookingService _bookingService = BookingService();

  final Map<String, dynamic> _dashboardData = {
    'myBooking': {'count': 0, 'growth': 8.2},
    'bookPlot': {'count': 5, 'growth': 15.7},
    'totalCommission': {'count': 28500, 'growth': 12.4},
    'commissionReceived': {'count': 18200, 'growth': 5.3},
    'addVisit': {'count': 0, 'growth': 0.0},
    'totalVisits': {'count': 47, 'growth': -2.1},
  };

  final List<Map<String, dynamic>> _notifications = [
    {'type': 'Booking', 'description': 'Plot #A-102 booked', 'time': '2 hours ago', 'icon': Icons.book_online, 'color': Colors.green},
    {'type': 'Visit', 'description': 'Site visit completed', 'time': '5 hours ago', 'icon': Icons.location_on, 'color': Colors.blue},
    {'type': 'Commission', 'description': '₹5,000 received', 'time': '1 day ago', 'icon': Icons.attach_money, 'color': Colors.orange},
    {'type': 'Lead', 'description': 'New lead assigned', 'time': '2 days ago', 'icon': Icons.person_add, 'color': Colors.purple},
  ];

  final List<Map<String, dynamic>> _performanceStats = [
    {'label': 'Conversion Rate', 'value': '24%', 'progress': 0.75, 'color': Colors.green},
    {'label': 'Visit to Booking', 'value': '18%', 'progress': 0.45, 'color': Colors.blue},
    {'label': 'Target Achievement', 'value': '82%', 'progress': 0.82, 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with widget data
    _userName = widget.userName;
    _userRole = widget.userRole;
    _profileImageUrl = widget.profileImageUrl;
    _userPhone = widget.phone;
    
    // Fetch real profile data from API
    _loadProfileData();
    // Fetch booking count
    _loadBookingCount();
  }
  
  /// Fetches profile data from API and updates UI + Session
  Future<void> _loadProfileData() async {
    if (_userPhone == null || _userPhone!.isEmpty) {
      // Try to get phone from session
      final session = await AuthManager.getCurrentSession();
      _userPhone = session?.userMobile ?? session?.phone;
    }
    
    if (_userPhone == null || _userPhone!.isEmpty) {
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'Phone number not available';
      });
      return;
    }

    try {
      // Fetch profile from API
      final profile = await _profileService.fetchProfile(_userPhone!);
      
      if (profile != null && mounted) {
        // Debug: Print received profile image URL
        print('📸 Profile Image URL from API: ${profile.profileImageUrl}');
        
        setState(() {
          _profile = profile;
          _userName = profile.fullName.isNotEmpty ? profile.fullName : 'Associate';
          _userEmail = profile.email;
          _userPhone = profile.phone;
          _associateId = profile.associateId;
          
          // Build profile image URL with better handling
          if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty) {
            String imageUrl = profile.profileImageUrl!.trim();
            
            // Check if URL already starts with http/https
            if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
              _profileImageUrl = imageUrl;
            } else {
              // Remove leading slash if exists
              if (imageUrl.startsWith('/')) {
                imageUrl = imageUrl.substring(1);
              }
              
              // If URL already contains a folder path (like "Uploads/"), don't add "Images/"
              // Otherwise add "Images/" prefix
              if (imageUrl.contains('/')) {
                // Already has a path (e.g., "Uploads/file.png")
                _profileImageUrl = 'https://realapp.cheenu.in/$imageUrl';
              } else {
                // Just a filename (e.g., "file.png")
                _profileImageUrl = 'https://realapp.cheenu.in/Images/$imageUrl';
              }
            }
            
            print('✅ Final Image URL: $_profileImageUrl');
          } else {
            print('⚠️ No profile image URL received from API');
            _profileImageUrl = null;
          }
          
          _isLoadingProfile = false;
          _profileError = null;
        });
        
        // Update session with real profile data for auto-login
        await _updateSessionWithProfile(profile);
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
      }
    }
  }
  
  /// Updates Hive session with fetched profile data
  Future<void> _updateSessionWithProfile(AssociateProfile profile) async {
    try {
      await AuthManager.updateSession(
        userName: profile.fullName,
        profilePic: profile.profileImageUrl,
      );
    } catch (e) {
      print('Error updating session: $e');
    }
  }

  Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssociateProfileScreen(phone: _userPhone ?? widget.phone),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        _userName = result['name'] ?? _userName;
        _userRole = result['position'] ?? _userRole;
        _profileImageUrl = result['profileImageUrl'];
      });
      // Reload profile data after changes
      _loadProfileData();
    }
  }
  
  /// Refresh profile data manually
  Future<void> _refreshProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });
    await _loadProfileData();
  }
  
  /// Fetch booking count from API and update dashboard
  Future<void> _loadBookingCount() async {
    try {
      // Get phone number
      String? phone = _userPhone ?? widget.phone;
      if (phone == null || phone.isEmpty) {
        final session = await AuthManager.getCurrentSession();
        phone = session?.userMobile ?? session?.phone;
      }
      
      if (phone == null || phone.isEmpty) {
        print('⚠️ Phone number not available for booking count');
        return;
      }
      
      // Fetch bookings
      final bookings = await _bookingService.fetchBookingsForPhone(phone);
      
      // Update dashboard data with actual count
      if (mounted) {
        setState(() {
          _dashboardData['myBooking']['count'] = bookings.length;
        });
        print('✅ Booking count updated: ${bookings.length}');
      }
    } catch (e) {
      print('❌ Error loading booking count: $e');
      // Keep default count (0) on error
    }
  }

  List<DashboardItem> get items => [
    DashboardItem(
      title: "My Total Booking",
      icon: Icons.book_online,
      color: Colors.deepPurple,
      count: _dashboardData['myBooking']['count'],
      growth: (_dashboardData['myBooking']['growth'] as num).toDouble(),
    ),
    DashboardItem(
      title: "Book New Plot",
      icon: Icons.home_work,
      color: Colors.teal,
      count: _dashboardData['bookPlot']['count'],
      growth: (_dashboardData['bookPlot']['growth'] as num).toDouble(),
    ),
    DashboardItem(
      title: "Total Income",
      icon: Icons.payments,
      color: Colors.green,
      count: _dashboardData['commissionReceived']['count'],
      growth: (_dashboardData['commissionReceived']['growth'] as num).toDouble(),
      isCurrency: true,
    ),
    DashboardItem(
      title: "Income History",
      icon: Icons.attach_money,
      color: Colors.orange,
      count: _dashboardData['totalCommission']['count'],
      growth: (_dashboardData['totalCommission']['growth'] as num).toDouble(),
      isCurrency: true,
    ),

    DashboardItem(
      title: "Add client Visit",
      icon: Icons.person_add,
      color: Colors.blue,
      count: _dashboardData['addVisit']['count'],
      growth: (_dashboardData['addVisit']['growth'] as num).toDouble(),
    ),
    DashboardItem(
      title: "Our Total lists",
      icon: Icons.location_city,
      color: Colors.red,
      count: _dashboardData['totalVisits']['count'],
      growth: (_dashboardData['totalVisits']['growth'] as num).toDouble(),
    ),
  ];

  void _handleDrawerItemClick(String title) async {
    Navigator.pop(context);

    if (title == "Logout") {
      // Clear Hive session
      await AuthManager.clearSession();
      // Clear attendance state
      await AttendanceManager.clearCheckIn();
      
      // Navigate to role selection screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false,
      );
    } else if (title == "My Booking") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BookPlotScreenNoNav()),
      );
    } else if (title == "My profile") {
      _navigateToProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$title clicked"), backgroundColor: Colors.deepPurple),
      );
    }
  }

  void _refreshData() {
    setState(() {
      _dashboardData['myBooking']['count'] += 1;
      _dashboardData['totalVisits']['count'] += 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Associate Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              _refreshData();
              _refreshProfile();
              _loadBookingCount();
            }, 
            tooltip: 'Refresh Data'
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications'))),
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner if profile failed to load
            if (_buildErrorBanner() != null) _buildErrorBanner()!,
            
            _buildWelcomeHeader(),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            _buildDashboardGrid(),
            const SizedBox(height: 20),
             _buildNotifications()
          ],
        ),
      ),

    );
  }

  // PROFILE PIC FROM API - Dynamic with Loading State
  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple.shade600, Colors.purple.shade400]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Profile Avatar with Loading State
          Stack(
            children: [
              _buildProfileAvatar(radius: 30),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome back!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  _isLoadingProfile ? 'Loading...' : _userName,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 24, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (_associateId != null && _associateId!.isNotEmpty)
                  Text(
                    'ID: $_associateId',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  )
                else
                  Text(_userRole, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.yellow.shade400, size: 16),
                const SizedBox(width: 4),
                Text("4.8 Rating", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDashboardGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.3),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return DashboardCard(
              item: item,
              onTap: () {
                if (item.title == "My Total Booking") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingScreen ()));
                } else if (item.title == "Book New Plot") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BookPlotScreenNoNav()));
                } else if (item.title == "Total Income") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalBookingListScreen()));
                } else if (item.title == "Income History") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const  PaymentReceivedScreen()));
                } else if (item.title == "add Client Visit") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommissionListScreen(), // Correct
                    ),
                  );
                } else if (item.title == "Our Total lists") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommissionListScreen()



                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${item.title} clicked"), backgroundColor: item.color),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Notifications",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: _notifications.map((item) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 20,
                  ),
                ),
                title: Text(
                  item['type'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(item['description'] as String),
                trailing: Text(
                  item['time'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // DRAWER WITH DYNAMIC PROFILE DATA
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.deepPurple.shade800),
              child: Column(
                children: [
                  // Profile Avatar with Status Indicator
                  Stack(
                    children: [
                      _buildProfileAvatar(radius: 40),
                      if (_profile != null && _profile!.status)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // User Name with Loading State
                  Text(
                    _isLoadingProfile ? 'Loading...' : _userName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  // Phone Number
                  Text(
                    _userPhone ?? widget.phone,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  // Email if available
                  if (_userEmail != null && _userEmail!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      _userEmail!,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _profile != null && _profile!.status
                          ? Colors.green.withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _profile != null && _profile!.status ? "Active Associate" : "Premium Associate",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  // Associate ID if available
                  if (_associateId != null && _associateId!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ID: $_associateId',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerSection("MAIN", [
                    _buildDrawerItem("Dashboard", Icons.dashboard, Colors.deepPurple),
                    _buildDrawerItem("My Leads", Icons.leaderboard, Colors.blue),


                    _buildDrawerItem("My Booking", Icons.book_online, Colors.green),
                  ]),
                  _buildDrawerSection("FINANCE", [
                    _buildDrawerItem("Income History", Icons.attach_money, Colors.orange),
                    _buildDrawerItem("Total income", Icons.payments, Colors.teal),
                  ]),
                  _buildDrawerSection("OPERATIONS", [
                    _buildDrawerItem("Book New Plot", Icons.home_work, Colors.indigo),
                    _buildDrawerItem("Our Visit list", Icons.location_city, Colors.red),
                    _buildDrawerItem("Add Client Visit ", Icons.add_location_alt, Colors.pink),
                  ]),
                  _buildDrawerSection("SETTINGS", [
                    _buildDrawerItem("Settings", Icons.settings, Colors.grey),
                    _buildDrawerItem("My profile", Icons.person, Colors.blue),
                    _buildDrawerItem("Logout", Icons.logout, Colors.red),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Divider(color: Colors.white54),
                  const SizedBox(height: 8),
                  Text("RealEstate Pro v1.0.0", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
      onTap: () => _handleDrawerItemClick(title),
    );
  }

  // REUSABLE: Build profile avatar with better image handling
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              )
            : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _profileImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print('❌ Image load error for $url: $error');
                      return Container(
                        color: Colors.deepPurple.shade100,
                        child: Icon(
                          Icons.person,
                          size: radius * 1.2,
                          color: Colors.deepPurple.shade300,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.deepPurple.shade100,
                    child: Icon(
                      Icons.person,
                      size: radius * 1.2,
                      color: Colors.deepPurple.shade300,
                    ),
                  ),
      ),
    );
  }
  
  // REUSABLE: Get profile image with fallback and error handling (kept for compatibility)
  ImageProvider _getProfileImageProvider() {
    // Priority: 1. Fetched profile image, 2. Widget prop, 3. Default
    String? imageUrl = _profileImageUrl;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      print('🖼️ Loading image from: $imageUrl');
      
      return CachedNetworkImageProvider(
        imageUrl,
        errorListener: (error) {
          print('❌ Error loading profile image from $imageUrl: $error');
        },
      );
    }
    
    print('📷 Using default avatar - no image URL available');
    // Fallback to default avatar
    return const AssetImage('assets/logo3.png'); // Using your app logo as fallback
  }
  
  /// Display error message if profile loading failed
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

// DashboardItem and DashboardCard (unchanged)
class DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final double growth;
  final bool isCurrency;

  const DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.growth,
    this.isCurrency = false,
  });
}

class DashboardCard extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const DashboardCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [item.color.withOpacity(0.1), item.color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: item.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: item.growth >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: item.growth >= 0 ? Colors.green : Colors.red, size: 12),
                        const SizedBox(width: 2),
                        Text("${item.growth.abs().toStringAsFixed(1)}%", style: TextStyle(color: item.growth >= 0 ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.isCurrency ? "₹${_formatCurrency(item.count)}" : item.count.toString(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: item.color),
                  ),
                  const SizedBox(height: 4),
                  Text(item.title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }
}
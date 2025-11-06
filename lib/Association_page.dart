import 'package:flutter/material.dart';
import '/Add_associate/associate_profile_screen.dart';
import '/signin_role/sign_role_associate.dart';
import '/plot_screen/book_plot.dart';
import '/asscoiate_plot_scren/book_plot.dart';
import '/screens/add_visit_screen.dart';           // NEW
import '/screens/total_visits_screen.dart';         // NEW
import '/screens/total_commission_screen.dart';       // NEW
import '/screens/commission_received_screen.dart';   // NEW
import '/screens/book_plot_screen.dart';
import'/screens/commission_received_screen.dart';

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
  late String _userName;
  late String _userRole;
  String? _profileImageUrl;

  final Map<String, dynamic> _dashboardData = {
    'myBooking': {'count': 12, 'growth': 8.2},
    'bookPlot': {'count': 5, 'growth': 15.7},
    'totalCommission': {'count': 28500, 'growth': 12.4},
    'commissionReceived': {'count': 18200, 'growth': 5.3},
    'addVisit': {'count': 0, 'growth': 0.0},
    'totalVisits': {'count': 47, 'growth': -2.1},
  };

  final List<Map<String, dynamic>> _recentActivities = [
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
    _userName = widget.userName;
    _userRole = widget.userRole;
    _profileImageUrl = widget.profileImageUrl;
  }

  Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssociateProfileScreen(phone: widget.phone),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        _userName = result['name'] ?? _userName;
        _userRole = result['position'] ?? _userRole;
        _profileImageUrl = result['profileImageUrl'];
      });
    }
  }

  List<DashboardItem> get items => [
    DashboardItem(
      title: "My Booking",
      icon: Icons.book_online,
      color: Colors.deepPurple,
      count: _dashboardData['myBooking']['count'],
      growth: (_dashboardData['myBooking']['growth'] as num).toDouble(),
    ),
    DashboardItem(
      title: "Book Plot",
      icon: Icons.home_work,
      color: Colors.teal,
      count: _dashboardData['bookPlot']['count'],
      growth: (_dashboardData['bookPlot']['growth'] as num).toDouble(),
    ),
    DashboardItem(
      title: "Total Commission",
      icon: Icons.attach_money,
      color: Colors.orange,
      count: _dashboardData['totalCommission']['count'],
      growth: (_dashboardData['totalCommission']['growth'] as num).toDouble(),
      isCurrency: true,
    ),
    DashboardItem(
      title: "Commission Received",
      icon: Icons.payments,
      color: Colors.green,
      count: _dashboardData['commissionReceived']['count'],
      growth: (_dashboardData['commissionReceived']['growth'] as num).toDouble(),
      isCurrency: true,
    ),
    DashboardItem(
      title: "Add Visit",
      icon: Icons.add_location_alt,
      color: Colors.blue,
      count: _dashboardData['addVisit']['count'],
      growth: (_dashboardData['addVisit']['growth'] as num).toDouble(),
    ),
    DashboardItem(
      title: "Total Visits",
      icon: Icons.location_city,
      color: Colors.red,
      count: _dashboardData['totalVisits']['count'],
      growth: (_dashboardData['totalVisits']['growth'] as num).toDouble(),
    ),
  ];

  void _handleDrawerItemClick(String title) {
    Navigator.pop(context);

    if (title == "Logout") {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AssociateLoginScreen()),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData, tooltip: 'Refresh Data'),
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
            _buildWelcomeHeader(),
            const SizedBox(height: 20),
            _buildPerformanceStats(),
            const SizedBox(height: 20),
            _buildDashboardGrid(),
            const SizedBox(height: 20),
            _buildRecentActivities(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add new visit/booking'))),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // DUMMY PHOTO + API NAME
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? NetworkImage(_profileImageUrl!)
                    : const AssetImage('assets/download (1).jpeg') as ImageProvider, // DUMMY PHOTO
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome back!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_userName, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 24, fontWeight: FontWeight.bold)), // API NAME
                const SizedBox(height: 4),
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

  Widget _buildPerformanceStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Performance Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8),
          itemCount: _performanceStats.length,
          itemBuilder: (context, index) {
            final stat = _performanceStats[index];
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: stat['progress'] as double, backgroundColor: Colors.grey.shade200, color: stat['color'] as Color, strokeWidth: 6),
                  const SizedBox(height: 12),
                  Text(stat['value'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stat['color'] as Color)),
                  const SizedBox(height: 4),
                  Text(stat['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            );
          },
        ),
      ],
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
                // NEW NAVIGATION LOGIC
                if (item.title == "My Booking") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BookPlotScreenNoNav()));
                }
                else if (item.title == "Book Plot") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BookPlotScreen()));
                }
                else if (item.title == "Add Visit") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalBookingListScreen()));
                }


                else if (item.title == "Commission Received") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommissionListScreen(
                       // Replace with actual phone variable
                      ),
                    ),
                  );
                }
                else {
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

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recent Activities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(
            children: _recentActivities.map((activity) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: (activity['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 20),
                ),
                title: Text(activity['type'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(activity['description'] as String),
                trailing: Text(activity['time'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // DUMMY PHOTO + API NAME + PHONE NUMBER
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('assets/download (1).jpeg') as ImageProvider, // DUMMY PHOTO
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), // API NAME
                  const SizedBox(height: 5),
                  Text(widget.phone, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)), // PHONE NUMBER
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text("Premium Associate", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
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
                    _buildDrawerItem("Total Commission", Icons.attach_money, Colors.orange),
                    _buildDrawerItem("Commission Received", Icons.payments, Colors.teal),
                  ]),
                  _buildDrawerSection("OPERATIONS", [
                    _buildDrawerItem("Book Plot", Icons.home_work, Colors.indigo),
                    _buildDrawerItem("Total Visit", Icons.location_city, Colors.red),
                    _buildDrawerItem("Add Visit", Icons.add_location_alt, Colors.pink),
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
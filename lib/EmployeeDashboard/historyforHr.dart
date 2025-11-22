import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/AttendanceRecord.dart';
import '/Model/attendance_summary.dart';
import '/service/attendancerecordService.dart';

class AttendanceScreentHr extends StatefulWidget {
  const AttendanceScreentHr({Key? key}) : super(key: key);

  @override
  State<AttendanceScreentHr> createState() => _AttendanceScreentHrState();
}

class _AttendanceScreentHrState extends State<AttendanceScreentHr> with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  late TabController _tabController;

  // Tab data
  List<PendingAttendance> _pendingAttendance = [];
  List<AttendanceRecord> _allAttendance = [];
  List<AbsentStaff> _absentStaff = [];
  
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _loadDataForTab(_tabController.index);
      }
    });
    _loadDataForTab(0); // Load Today tab by default
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDataForTab(int tabIndex) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      switch (tabIndex) {
        case 0: // Today - Pending attendance
          await _fetchPendingAttendance();
          break;
        case 1: // Weeks
          await _fetchAttendanceForWeeks();
          break;
        case 2: // Months
          await _fetchAttendanceForMonths();
          break;
        case 3: // All - Absent staff
          await _fetchAbsentStaff();
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch pending attendance from API
  Future<void> _fetchPendingAttendance() async {
    try {
      final response = await http.get(
        Uri.parse('https://realapp.cheenu.in/api/attendance/pending'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            _pendingAttendance = (data['data'] as List)
                .map((item) => PendingAttendance.fromJson(item))
                .toList();
          });
        }
      } else {
        throw Exception('Failed to load pending attendance');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  // Fetch attendance for weeks (last 7 days)
  Future<void> _fetchAttendanceForWeeks() async {
    try {
      final response = await _attendanceService.getAttendanceRecords();
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      setState(() {
        _allAttendance = response.data.where((record) {
          return record.createDate.isAfter(weekAgo);
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  // Fetch attendance for months (last 30 days)
  Future<void> _fetchAttendanceForMonths() async {
    try {
      final response = await _attendanceService.getAttendanceRecords();
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));
      
      setState(() {
        _allAttendance = response.data.where((record) {
          return record.createDate.isAfter(monthAgo);
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  // Fetch absent staff from API
  Future<void> _fetchAbsentStaff() async {
    try {
      final response = await http.get(
        Uri.parse('https://realapp.cheenu.in/Api/AbsentStaffAttendenceRecord'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['absentStaff'] != null) {
          setState(() {
            _absentStaff = (data['absentStaff'] as List)
                .map((item) => AbsentStaff.fromJson(item))
                .toList();
          });
        }
      } else {
        throw Exception('Failed to load absent staff');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _approveRecord(String id) async {
    final result = await _attendanceService.acceptAttendance(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.green),
      );
    }
    _removePendingRecord(id);
  }

  Future<void> _rejectRecord(String id) async {
    final result = await _attendanceService.rejectAttendance(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
    _removePendingRecord(id);
  }

  void _removePendingRecord(String id) {
    setState(() {
      _pendingAttendance.removeWhere((record) => record.id.toString() == id);
    });
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return 'https://realapp.cheenu.in$normalized';
  }

  void _showImagePreview(String url, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  _resolveImageUrl(url),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey.shade300,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.red),
                          SizedBox(height: 8),
                          Text('Failed to load image'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Records',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Weeks'),
            Tab(text: 'Months'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _loadDataForTab(_currentTabIndex),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDataForTab(_currentTabIndex),
        color: Colors.blueAccent,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTodayTab(),
            _buildWeeksTab(),
            _buildMonthsTab(),
            _buildAllTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_pendingAttendance.isEmpty) {
      return const Center(child: Text('No pending attendance records'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingAttendance.length,
      itemBuilder: (context, index) {
        final record = _pendingAttendance[index];
        return _buildPendingAttendanceCard(record);
      },
    );
  }

  Widget _buildPendingAttendanceCard(PendingAttendance record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xfffdfbfb), Color(0xffebedee)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade800,
                child: Text(
                  record.employeeName.isNotEmpty
                      ? record.employeeName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.employeeName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      record.employeeType,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      record.status,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: DateFormat('dd MMM, hh:mm a').format(record.createDate),
                ),
                const Divider(height: 18),
                _infoTile(
                  icon: Icons.login,
                  label: 'Check-in',
                  value: DateFormat('dd MMM, hh:mm a').format(record.checkInTime),
                  helper: record.checkInLocation,
                ),
                if (record.checkOutTime != null) ...[
                  const SizedBox(height: 8),
                  _infoTile(
                    icon: Icons.logout,
                    label: 'Check-out',
                    value: DateFormat('dd MMM, hh:mm a').format(record.checkOutTime!),
                    helper: record.checkOutLocation,
                  ),
                ],
                if (record.hoursWorked.isNotEmpty) ...[
                  const Divider(height: 18),
                  _infoTile(
                    icon: Icons.access_time,
                    label: 'Hours Worked',
                    value: record.hoursWorked,
                  ),
                ],
                if (record.empMob.isNotEmpty) ...[
                  const Divider(height: 18),
                  _infoTile(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: record.empMob,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Image icons row
          Row(
            children: [
              if (record.checkInImage.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImagePreview(record.checkInImage, 'Check-in Image'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text('Check-in', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              if (record.checkInImage.isNotEmpty && record.checkOutImage.isNotEmpty)
                const SizedBox(width: 8),
              if (record.checkOutImage.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImagePreview(record.checkOutImage, 'Check-out Image'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text('Check-out', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Accept/Reject buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRecord(record.id.toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectRecord(record.id.toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeksTab() {
    return _buildAttendanceListTab();
  }

  Widget _buildMonthsTab() {
    return _buildAttendanceListTab();
  }

  Widget _buildAttendanceListTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_allAttendance.isEmpty) {
      return const Center(child: Text('No attendance records found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allAttendance.length,
      itemBuilder: (context, index) {
        final record = _allAttendance[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xfffdfbfb), Color(0xffebedee)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade800,
                child: Text(
                  record.employeeName.isNotEmpty
                      ? record.employeeName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.employeeName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      record.employeeType,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: DateFormat('dd MMM, hh:mm a').format(record.createDate),
                ),
                const Divider(height: 18),
                _infoTile(
                  icon: Icons.login,
                  label: 'Check-in',
                  value: DateFormat('dd MMM, hh:mm a').format(record.checkInTime),
                  helper: record.checkInLocation,
                ),
                if (record.checkOutTime != null) ...[
                  const SizedBox(height: 8),
                  _infoTile(
                    icon: Icons.logout,
                    label: 'Check-out',
                    value: DateFormat('dd MMM, hh:mm a').format(record.checkOutTime!),
                    helper: record.checkOutLocation,
                  ),
                ],
                if (record.hoursWorked != null && record.hoursWorked!.isNotEmpty) ...[
                  const Divider(height: 18),
                  _infoTile(
                    icon: Icons.access_time,
                    label: 'Hours Worked',
                    value: record.hoursWorked!,
                  ),
                ],
                if (record.empMob.isNotEmpty) ...[
                  const Divider(height: 18),
                  _infoTile(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: record.empMob,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Image icons row
          Row(
            children: [
              if (record.checkInImage.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImagePreview(record.checkInImage, 'Check-in Image'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text('Check-in', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              if (record.checkInImage.isNotEmpty && record.checkOutImage != null && record.checkOutImage!.isNotEmpty)
                const SizedBox(width: 8),
              if (record.checkOutImage != null && record.checkOutImage!.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImagePreview(record.checkOutImage!, 'Check-out Image'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text('Check-out', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_absentStaff.isEmpty) {
      return const Center(child: Text('No absent staff records'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _absentStaff.length,
      itemBuilder: (context, index) {
        final staff = _absentStaff[index];
        return _buildAbsentStaffCard(staff);
      },
    );
  }

  Widget _buildAbsentStaffCard(AbsentStaff staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xffffebee), Color(0xfffce4ec)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade800,
                child: Text(
                  staff.fullname.isNotEmpty
                      ? staff.fullname[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.fullname,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      staff.position,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      staff.status,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.badge,
                  label: 'Staff ID',
                  value: staff.staffId,
                ),
                const Divider(height: 18),
                _infoTile(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: staff.phone,
                ),
                const Divider(height: 18),
                _infoTile(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: staff.date != null
                      ? DateFormat('dd MMM, yyyy').format(staff.date!)
                      : 'N/A',
                ),
                const Divider(height: 18),
                _infoTile(
                  icon: Icons.info,
                  label: 'Action',
                  value: staff.action,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    String? helper,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blueGrey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (helper != null && helper.isNotEmpty)
                Text(
                  helper,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Model classes
class PendingAttendance {
  final int id;
  final String employeeName;
  final String empId;
  final String empMob;
  final String employeeType;
  final DateTime createDate;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String checkInLocation;
  final String checkOutLocation;
  final String checkInImage;
  final String checkOutImage;
  final String hoursWorked;
  final String status;
  final String action;
  final String? adminAction;

  PendingAttendance({
    required this.id,
    required this.employeeName,
    required this.empId,
    required this.empMob,
    required this.employeeType,
    required this.createDate,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLocation,
    required this.checkOutLocation,
    required this.checkInImage,
    required this.checkOutImage,
    required this.hoursWorked,
    required this.status,
    required this.action,
    this.adminAction,
  });

  factory PendingAttendance.fromJson(Map<String, dynamic> json) {
    return PendingAttendance(
      id: json['Id'] ?? 0,
      employeeName: json['EmployeeName'] ?? '',
      empId: json['EmpId'] ?? '',
      empMob: json['EmpMob'] ?? '',
      employeeType: json['EmployeeType'] ?? '',
      createDate: DateTime.parse(json['Createdate'] ?? DateTime.now().toIso8601String()),
      checkInTime: DateTime.parse(json['CheckInTime'] ?? DateTime.now().toIso8601String()),
      checkOutTime: json['CheckOutTime'] != null
          ? DateTime.parse(json['CheckOutTime'])
          : null,
      checkInLocation: json['CheckInLocation'] ?? '',
      checkOutLocation: json['CheckOutLocation'] ?? '',
      checkInImage: json['CheckInImage'] ?? '',
      checkOutImage: json['CheckOutImage'] ?? '',
      hoursWorked: json['HoursWorked'] ?? '',
      status: json['Status'] ?? '',
      action: json['Action'] ?? '',
      adminAction: json['AdminAction'],
    );
  }
}

class AbsentStaff {
  final String staffId;
  final String fullname;
  final String phone;
  final String position;
  final DateTime? date;
  final String status;
  final String action;

  AbsentStaff({
    required this.staffId,
    required this.fullname,
    required this.phone,
    required this.position,
    this.date,
    required this.status,
    required this.action,
  });

  factory AbsentStaff.fromJson(Map<String, dynamic> json) {
    return AbsentStaff(
      staffId: json['Staff_Id'] ?? '',
      fullname: json['Fullname'] ?? '',
      phone: json['Phone'] ?? '',
      position: json['Position'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : null,
      status: json['Status'] ?? '',
      action: json['Action'] ?? '',
    );
  }
}

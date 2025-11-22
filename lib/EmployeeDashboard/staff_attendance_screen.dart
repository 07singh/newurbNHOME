import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/Model/staff_attendance_model.dart';
import '/service/staff_attendance_service.dart';

class StaffAttendanceScreen extends StatefulWidget {
  final String phone;
  const StaffAttendanceScreen({super.key, required this.phone});

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<StaffAttendance>> _futureAttendance;
  final StaffAttendanceService _service = StaffAttendanceService();
  late TabController _tabController;
  
  // History filter states
  String _selectedFilter = 'All'; // All, Yesterday, Week, Month, Custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<StaffAttendance> _allRecords = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _futureAttendance = _service.fetchAttendanceByPhone(widget.phone);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filter records for today
  List<StaffAttendance> _getTodayRecords(List<StaffAttendance> records) {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    
    return records.where((record) {
      if (record.checkInTime.isEmpty) return false;
      try {
        // Parse the check-in time to get the date
        DateTime checkInDate;
        if (record.checkInTime.contains('T')) {
          checkInDate = DateTime.parse(record.checkInTime.split('T')[0]);
        } else if (record.checkInTime.contains(' ')) {
          checkInDate = DateTime.parse(record.checkInTime.split(' ')[0]);
        } else {
          checkInDate = DateTime.parse(record.checkInTime);
        }
        final recordDateStr = DateFormat('yyyy-MM-dd').format(checkInDate);
        return recordDateStr == todayStr;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Filter records based on selected filter
  List<StaffAttendance> _getFilteredRecords(List<StaffAttendance> records) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return _filterByDateRange(records, yesterday, yesterday);
        
      case 'Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return _filterByDateRange(records, weekStart, now);
        
      case 'Month':
        final monthStart = DateTime(now.year, now.month, 1);
        return _filterByDateRange(records, monthStart, now);
        
      case 'Custom':
        if (_customStartDate != null && _customEndDate != null) {
          return _filterByDateRange(records, _customStartDate!, _customEndDate!);
        }
        return records;
        
      case 'All':
      default:
        return records;
    }
  }

  // Filter records by date range
  List<StaffAttendance> _filterByDateRange(
      List<StaffAttendance> records, DateTime startDate, DateTime endDate) {
    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);
    
    return records.where((record) {
      if (record.checkInTime.isEmpty) return false;
      try {
        DateTime checkInDate;
        if (record.checkInTime.contains('T')) {
          checkInDate = DateTime.parse(record.checkInTime.split('T')[0]);
        } else if (record.checkInTime.contains(' ')) {
          checkInDate = DateTime.parse(record.checkInTime.split(' ')[0]);
        } else {
          checkInDate = DateTime.parse(record.checkInTime);
        }
        final recordDateStr = DateFormat('yyyy-MM-dd').format(checkInDate);
        return recordDateStr.compareTo(startStr) >= 0 && 
               recordDateStr.compareTo(endStr) <= 0;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Show date picker for custom range
  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF871BBF),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "My Attendance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF871BBF),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.today),
              text: "Today's Attendance",
            ),
            Tab(
              icon: Icon(Icons.history),
              text: "History",
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<StaffAttendance>>(
        future: _futureAttendance,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureAttendance = _service.fetchAttendanceByPhone(widget.phone);
                      });
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final allRecords = snapshot.data ?? [];
          _allRecords = allRecords;

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Today's Attendance
              _buildTodayTab(allRecords),
              // Tab 2: History
              _buildHistoryTab(allRecords),
            ],
          );
        },
      ),
    );
  }

  // Build Today's Attendance Tab
  Widget _buildTodayTab(List<StaffAttendance> allRecords) {
    final todayRecords = _getTodayRecords(allRecords);

    if (todayRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "No attendance records for today",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _futureAttendance = _service.fetchAttendanceByPhone(widget.phone);
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: todayRecords.length,
        itemBuilder: (context, index) {
          return _buildAttendanceCard(todayRecords[index]);
        },
      ),
    );
  }

  // Build History Tab
  Widget _buildHistoryTab(List<StaffAttendance> allRecords) {
    final filteredRecords = _getFilteredRecords(allRecords);

    return Column(
      children: [
        // Filter Section
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter by:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', _selectedFilter == 'All'),
                  _buildFilterChip('Yesterday', _selectedFilter == 'Yesterday'),
                  _buildFilterChip('Week', _selectedFilter == 'Week'),
                  _buildFilterChip('Month', _selectedFilter == 'Month'),
                  _buildFilterChip('Custom', _selectedFilter == 'Custom'),
                ],
              ),
              if (_selectedFilter == 'Custom') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectCustomDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: Color(0xFF871BBF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _customStartDate != null && _customEndDate != null
                                      ? '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}'
                                      : 'Select Date Range',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _customStartDate != null ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Records List
        Expanded(
          child: filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No attendance records found",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _futureAttendance = _service.fetchAttendanceByPhone(widget.phone);
                    });
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      return _buildAttendanceCard(filteredRecords[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Build Filter Chip
  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          if (label != 'Custom') {
            _customStartDate = null;
            _customEndDate = null;
          }
        });
      },
      selectedColor: const Color(0xFF871BBF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildAttendanceCard(StaffAttendance record) {
    // Extract date from check-in time
    String displayDate = 'N/A';
    try {
      DateTime checkInDate;
      if (record.checkInTime.contains('T')) {
        checkInDate = DateTime.parse(record.checkInTime.split('T')[0]);
      } else if (record.checkInTime.contains(' ')) {
        checkInDate = DateTime.parse(record.checkInTime.split(' ')[0]);
      } else {
        checkInDate = DateTime.parse(record.checkInTime);
      }
      displayDate = DateFormat('MMM dd, yyyy').format(checkInDate);
    } catch (e) {
      displayDate = record.checkInTime;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.employeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: record.status.toLowerCase() == "present"
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.status.isEmpty ? "Unknown" : record.status,
                  style: TextStyle(
                    color: record.status.toLowerCase() == "present"
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow("Employee Type", record.employeeType),
          _infoRow("Check In", _formatTime(record.checkInTime)),
          _infoRow("Check Out", _formatTime(record.checkOutTime)),
          _infoRow("Location In", record.checkInLocation),
          _infoRow("Location Out", record.checkOutLocation),
          _infoRow("Hours Worked", record.hoursWorked),
          _infoRow("Action", record.action),
          const SizedBox(height: 10),
          Row(
            children: [
              if (record.checkInImage.isNotEmpty)
                Expanded(
                  child: _imageBox(
                      "Check-In",
                      "https://realapp.cheenu.in${record.checkInImage}"),
                ),
              const SizedBox(width: 10),
              if (record.checkOutImage.isNotEmpty)
                Expanded(
                  child: _imageBox(
                      "Check-Out",
                      "https://realapp.cheenu.in${record.checkOutImage}"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "N/A" : value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return "N/A";
    try {
      // Try to parse and format the datetime
      DateTime dateTime;
      if (timeString.contains('T')) {
        dateTime = DateTime.parse(timeString);
      } else if (timeString.contains(' ')) {
        dateTime = DateTime.parse(timeString);
      } else {
        return timeString;
      }
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return timeString;
    }
  }

  Widget _imageBox(String label, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                      title: Text(label),
                      backgroundColor: const Color(0xFF871BBF),
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                    Flexible(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("Failed to load image"),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

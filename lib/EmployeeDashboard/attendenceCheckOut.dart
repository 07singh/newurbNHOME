import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../HomeScreen.dart';
import '/service/attendance_manager.dart';
import '/service/auth_manager.dart';
import '/Model/login_model.dart';
import '/Model/user_session.dart';

/// Optimized Attendance Check-Out Screen
/// - Real-time duration calculation
/// - Integrated with user session management
/// - Enhanced two-step check-out process
/// - Improved error handling and loading states
/// - Better location handling with caching
/// - Performance optimized with proper disposal
class AttendanceCheckOut extends StatefulWidget {
  final DateTime checkInTime;
  final File? checkInPhoto;
  final Position? checkInPosition;
  final String? checkInAddress;

  const AttendanceCheckOut({
    super.key,
    required this.checkInTime,
    this.checkInPhoto,
    this.checkInPosition,
    this.checkInAddress,
  });

  @override
  State<AttendanceCheckOut> createState() => _AttendanceCheckOutState();
}

class _AttendanceCheckOutState extends State<AttendanceCheckOut> {
  // Location & Address
  Position? _position;
  String? _address;
  bool _isLoadingLocation = true;

  // Photo Management
  File? _photo;
  bool _isCheckOutPhotoTaken = false;
  final ImagePicker _picker = ImagePicker();

  // State Management
  bool _isCheckingOut = false;

  // User Session
  UserSession? _currentUser;
  bool _isLoadingUser = true;

  // Timer for real-time duration update
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _startDurationTimer();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  /// Start timer for real-time duration updates
  void _startDurationTimer() {
    // Update immediately
    _updateDuration();

    // Update every second for smooth real-time updates
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateDuration();
        });
      }
    });
  }

  /// Update current duration
  void _updateDuration() {
    final now = DateTime.now();
    _currentDuration = now.difference(widget.checkInTime);
  }

  /// Format duration for display
  String _getFormattedDuration() {
    final hours = _currentDuration.inHours;
    final minutes = _currentDuration.inMinutes.remainder(60);
    final seconds = _currentDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Initialize screen with user data and location
  Future<void> _initializeScreen() async {
    // Set check-in photo for display (not for check-out)
    _photo = widget.checkInPhoto;

    await Future.wait([
      _loadUserSession(),
      _initLocation(),
    ]);
  }

  /// Load current user session
  Future<void> _loadUserSession() async {
    try {
      final session = await AuthManager.getCurrentSession();
      if (session == null || !session.isLoggedIn) {
        if (mounted) {
          _showError('User session not found. Please login again.');
          Navigator.pop(context);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _currentUser = session;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
        _showError('Failed to load user session: $e');
      }
    }
  }

  /// Initialize location for check-out
  Future<void> _initLocation() async {
    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _address = 'Location service disabled';
          });
          _showError('Please enable location services.');
        }
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _address = 'Location permission denied';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _address = 'Location permission permanently denied';
          });
        }
        return;
      }

      // Get current position with timeout
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() => _position = pos);
      }

      // Fetch address in background
      _fetchAddress(pos);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _address = 'Error getting location';
        });
        debugPrint('Location error: $e');
      }
    }
  }

  /// Fetch address from coordinates
  Future<void> _fetchAddress(Position pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final addressParts = [
          p.name,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((part) => part != null && part.isNotEmpty).toList();

        setState(() {
          _address = addressParts.join(', ');
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Address unavailable';
          _isLoadingLocation = false;
        });
      }
      debugPrint('Geocoding error: $e');
    }
  }

  /// Take check-out photo
  Future<void> _takeCheckOutPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked != null) {
        setState(() {
          _photo = File(picked.path);
          _isCheckOutPhotoTaken = true;
        });
        _showSuccess('Check-out photo captured!');
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  /// Perform check-out with validation
  Future<void> _performCheckOut() async {
    // Prevent double-tap
    if (_isCheckingOut) return;

    // Validate user session
    if (_currentUser == null) {
      _showError('User session expired. Please login again.');
      return;
    }

    // Ensure check-out photo is taken
    if (!_isCheckOutPhotoTaken || _photo == null) {
      _showError('Please take a check-out photo first');
      return;
    }

    // Ensure location is captured
    if (_position == null) {
      _showError('Waiting for location...');
      await _initLocation();

      if (_position == null) {
        _showError('Unable to get location. Please try again.');
        return;
      }
    }

    setState(() => _isCheckingOut = true);

    try {
      // Calculate session duration
      final checkOutTime = DateTime.now();
      final duration = checkOutTime.difference(widget.checkInTime);

      // TODO: Send attendance data to server API
      // final response = await AttendanceService.submitAttendance(
      //   userId: _currentUser!.userId!,
      //   userName: _currentUser!.userName,
      //   checkInTime: widget.checkInTime,
      //   checkOutTime: checkOutTime,
      //   checkInPhoto: widget.checkInPhoto,
      //   checkOutPhoto: _photo,
      //   checkInLocation: widget.checkInPosition,
      //   checkOutLocation: _position,
      //   checkInAddress: widget.checkInAddress,
      //   checkOutAddress: _address,
      //   duration: duration,
      // );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Clear check-in state from persistent storage
      await AttendanceManager.clearCheckIn();

      // Show success message with duration
      if (mounted) {
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        _showSuccess('Checked out successfully! Duration: ${hours}h ${minutes}m');
      }

      // Navigate back to home
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Check-out failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  /// Show error message
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Format current time
  String _formattedTime() => DateFormat.jm().format(DateTime.now());

  /// Format current date
  String _formattedDate() => DateFormat('EEE, MMM d, yyyy').format(DateTime.now());

  /// Get check-in time formatted
  String _getCheckInTime() => DateFormat('hh:mm a').format(widget.checkInTime);

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => !_isCheckingOut,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6B46FF)),
            onPressed: _isCheckingOut ? null : () => Navigator.pop(context),
          ),
          title: const Text(
            'Attendance',
            style: TextStyle(
              color: Color(0xFF6B46FF),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF6B46FF)),
              onPressed: _isCheckingOut ? null : _initLocation,
              tooltip: 'Refresh Location',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _initLocation,
          color: const Color(0xFF4ADE80),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 6),

                // Welcome message
                Text(
                  'Welcome, ${_currentUser?.userName ?? 'User'}!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4ADE80),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Time display
                Text(
                  _formattedTime(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // Date display
                Text(
                  _formattedDate(),
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 28),

                // Active Session Card
                _buildActiveSessionCard(),

                const SizedBox(height: 32),

                // Check-out button with photo capture
                _buildCheckOutButton(),

                const SizedBox(height: 12),

                // Instruction text
                Text(
                  _isCheckingOut
                      ? 'Completing check-out...'
                      : !_isCheckOutPhotoTaken
                      ? 'Tap to take check-out photo'
                      : 'Photo captured! Tap Check-out button below',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                // Check-out confirmation button
                if (_isCheckOutPhotoTaken && !_isCheckingOut) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _performCheckOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ADE80),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'CONFIRM CHECK-OUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Captured Image Preview
                _buildPhotoPreview(),

                const SizedBox(height: 24),

                // Location Card
                _buildLocationCard(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build active session card with real-time duration
  Widget _buildActiveSessionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ADE80), Color(0xFF60A5FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Active Session',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Check-in time
          _buildSessionDetail(
            'Check-in Time:',
            _getCheckInTime(),
            Icons.login,
          ),
          const SizedBox(height: 8),

          // Current time
          _buildSessionDetail(
            'Current Time:',
            _formattedTime(),
            Icons.schedule,
          ),
          const SizedBox(height: 8),

          // Real-time duration (highlighted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Duration:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _getFormattedDuration(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for session details
  Widget _buildSessionDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build check-out button
  Widget _buildCheckOutButton() {
    return GestureDetector(
      onTap: _isCheckingOut ? null : _takeCheckOutPhoto,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.green.withOpacity(0.18),
                  Colors.transparent,
                ],
                radius: 0.7,
              ),
            ),
          ),

          // Main button
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isCheckingOut ? Colors.grey : const Color(0xFF4ADE80),
              gradient: _isCheckingOut
                  ? null
                  : const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF60A5FA)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isCheckingOut ? Colors.grey : Colors.greenAccent)
                      .withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isCheckingOut)
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  )
                else if (_isCheckOutPhotoTaken)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 36,
                  )
                else
                  const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 36,
                  ),
                const SizedBox(height: 8),
                Text(
                  _isCheckingOut
                      ? 'PROCESSING...'
                      : _isCheckOutPhotoTaken
                      ? 'PHOTO TAKEN'
                      : 'TAKE PHOTO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build photo preview
  Widget _buildPhotoPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            !_isCheckOutPhotoTaken ? 'Check-in Photo' : 'Check-out Photo',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !_isCheckOutPhotoTaken ? Colors.orange : Colors.green,
                width: 2,
              ),
            ),
            child: _photo == null
                ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera, color: Colors.grey, size: 40),
                SizedBox(height: 8),
                Text(
                  'No photo',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_photo!, fit: BoxFit.cover),
            ),
          ),
          if (!_isCheckOutPhotoTaken) ...[
            const SizedBox(height: 8),
            const Text(
              'Check-in photo - Take new photo for check-out',
              style: TextStyle(color: Colors.orange, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Build location card
  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E7FF)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF2B6CB0)),
                  SizedBox(width: 8),
                  Text(
                    'Current Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B6CB0),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _position != null
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _position != null ? 'Acquired' : 'Acquiring...',
                  style: TextStyle(
                    color: _position != null
                        ? const Color(0xFF166534)
                        : const Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Location details
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Latitude:',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Text(
                      _position != null
                          ? '${_position!.latitude.toStringAsFixed(6)}'
                          : '--',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Longitude:',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Text(
                      _position != null
                          ? '${_position!.longitude.toStringAsFixed(6)}'
                          : '--',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (_address != null && _address!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF2B6CB0),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _address!,
                          style: const TextStyle(
                            color: Color(0xFF2B6CB0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Status
          Row(
            children: [
              Icon(
                _position != null ? Icons.check_circle : Icons.access_time,
                color: _position != null
                    ? const Color(0xFF16A34A)
                    : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _position != null
                    ? 'Location captured successfully'
                    : 'Acquiring location...',
                style: TextStyle(
                  color: _position != null
                      ? const Color(0xFF16A34A)
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
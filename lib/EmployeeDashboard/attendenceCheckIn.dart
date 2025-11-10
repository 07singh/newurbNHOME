import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'attendenceCheckOut.dart';
import '/service/attendance_manager.dart';


class AttendanceCheckIn extends StatefulWidget {
  const AttendanceCheckIn({super.key});

  @override
  State<AttendanceCheckIn> createState() => _AttendanceCheckInState();
}

class _AttendanceCheckInState extends State<AttendanceCheckIn> {
  Position? _position;
  String? _address;
  File? _photo;
  final ImagePicker _picker = ImagePicker();
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permanently denied')),
        );
        return;
      }

      // ✅ Get the most accurate location
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      setState(() {
        _position = pos;
      });

      // ✅ Convert to detailed address
      try {
        List<Placemark> placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _address =
            '${p.name ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.subAdministrativeArea ?? ''}, ${p.administrativeArea ?? ''}, ${p.postalCode ?? ''}, ${p.country ?? ''}';
          });
        }
      } catch (e) {
        setState(() {
          _address = 'Unable to fetch address';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Error getting location: $e';
      });
    }
  }


  Future<void> _performCheckIn() async {
    if (_isCheckingIn) return;

    setState(() {
      _isCheckingIn = true;
    });

    try {
      // 1. Take photo
      final XFile? picked = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 75
      );

      if (picked == null) {
        setState(() {
          _isCheckingIn = false;
        });
        return;
      }

      setState(() {
        _photo = File(picked.path);
      });

      // 2. Ensure location is captured
      if (_position == null) {
        await _initLocation();
      }

      // 3. Save check-in state to persistent storage
      final checkInTime = DateTime.now();
      await AttendanceManager.saveCheckIn(
        checkInTime: checkInTime,
        checkInPhoto: _photo,
        checkInPosition: _position,
        checkInAddress: _address,
      );

      // 4. Simulate API call or processing delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // 5. Navigate to CheckOut page with data
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceCheckOut(
              checkInTime: checkInTime,
              checkInPhoto: _photo,
              checkInPosition: _position,
              checkInAddress: _address,
            ),
          ),
        );
      }

    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  String _formattedTime() {
    final now = DateTime.now();
    return DateFormat.jm().format(now);
  }

  String _formattedDate() {
    final now = DateTime.now();
    return DateFormat('EEE, MMM d, yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B46FF)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('Attendance', style: TextStyle(color: Color(0xFF6B46FF), fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF6B46FF)),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              const Text('Welcome To Attendifty!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(_formattedTime(), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(_formattedDate(), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 28),

              // Check-in button with glow
              GestureDetector(
                onTap: _performCheckIn,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // glow
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.purple.withOpacity(0.18), Colors.transparent],
                          radius: 0.7,
                        ),
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCheckingIn ? Colors.grey : const Color(0xFF6B46FF),
                        boxShadow: [
                          BoxShadow(
                            color: (_isCheckingIn ? Colors.grey : const Color(0xFF6B46FF)).withOpacity(0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isCheckingIn)
                            const CircularProgressIndicator(color: Colors.white)
                          else
                            const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                          const SizedBox(height: 8),
                          Text(
                              _isCheckingIn ? 'CHECKING IN...' : 'CHECK-IN',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                  _isCheckingIn ? 'Processing check-in...' : 'Tap to take photo for check-in',
                  style: const TextStyle(color: Colors.grey)
              ),
              const SizedBox(height: 24),

              // Location card
              Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: Color(0xFF2B6CB0)),
                            SizedBox(width: 8),
                            Text('Current Location', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2B6CB0))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _position != null ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _position != null ? 'Acquired' : 'Acquiring...',
                            style: TextStyle(
                                color: _position != null ? const Color(0xFF166534) : const Color(0xFF92400E),
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Latitude:', style: TextStyle(color: Colors.black54)),
                              Text(_position != null ? '${_position!.latitude.toStringAsFixed(6)}' : '--', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Longitude:', style: TextStyle(color: Colors.black54)),
                              Text(_position != null ? '${_position!.longitude.toStringAsFixed(6)}' : '--', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_address != null) Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFF2B6CB0)),
                              const SizedBox(width: 6),
                              Expanded(child: Text(_address!, style: const TextStyle(color: Color(0xFF2B6CB0), fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _position != null ? Icons.check_circle : Icons.access_time,
                          color: _position != null ? const Color(0xFF16A34A) : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _position != null ? 'Location captured successfully' : 'Acquiring location...',
                          style: TextStyle(color: _position != null ? const Color(0xFF16A34A) : Colors.orange),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Summary card (Today / This Week / Status)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('0 h 0 m', 'Today'),
                    _summaryItem('42h 15m', 'This Week'),
                    _summaryItem('Ready', 'Status'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Show captured photo preview
              if (_photo != null) Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Captured Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_photo!, width: 220, height: 220, fit: BoxFit.cover)),
                ],
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_today, color: Color(0xFF6B46FF)),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
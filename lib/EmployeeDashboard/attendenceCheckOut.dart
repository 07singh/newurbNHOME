import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../HomeScreen.dart';

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
  Position? _position;
  String? _address;
  File? _photo;
  bool _isCheckingOut = false;
  bool _isCheckOutPhotoTaken = false; // New flag to track if check-out photo is taken
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Use check-in photo only for display, but require new check-out photo
    _photo = widget.checkInPhoto;
    _isCheckOutPhotoTaken = false; // Initially no check-out photo taken
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _position = pos);

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _address = '${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}';
          });
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _takeCheckOutPhoto() async {
    final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75
    );
    if (picked != null) {
      setState(() {
        _photo = File(picked.path);
        _isCheckOutPhotoTaken = true; // Mark that check-out photo is taken
      });
    }
  }

  Future<void> _performCheckOut() async {
    if (_isCheckingOut) return;

    // Ensure we have a check-out photo (not the check-in photo)
    if (!_isCheckOutPhotoTaken || _photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a check-out photo first')),
      );
      return;
    }

    // Ensure location is captured
    if (_position == null) {
      await _initLocation();
      if (_position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waiting for location...')),
        );
        return;
      }
    }

    setState(() {
      _isCheckingOut = true;
    });

    try {
      // Simulate API call or processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checked out successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to home or previous screen
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-out failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
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

  String _getCheckInTime() {
    return DateFormat.jm().format(widget.checkInTime);
  }

  String _getDuration() {
    final now = DateTime.now();
    final difference = now.difference(widget.checkInTime);
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B46FF)),
          onPressed: _isCheckingOut ? null : () => Navigator.pop(context),
        ),
        title: const Text('Attendance', style: TextStyle(color: Color(0xFF6B46FF), fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B46FF)),
            onPressed: _isCheckingOut ? null : _initLocation,
          )
        ],
      ),
      body: SingleChildScrollView(
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

            // Active Session Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF60A5FA)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.access_time, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Active Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Checked in at: ${_getCheckInTime()}', style: const TextStyle(color: Colors.white)),
                  Text('Duration: ${_getDuration()}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Check-out button with photo capture
            GestureDetector(
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
                        colors: [Colors.green.withOpacity(0.18), Colors.transparent],
                        radius: 0.7,
                      ),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCheckingOut ? Colors.grey : const Color(0xFF4ADE80),
                      gradient: _isCheckingOut ? null : const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF60A5FA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isCheckingOut ? Colors.grey : Colors.greenAccent).withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isCheckingOut)
                          const CircularProgressIndicator(color: Colors.white)
                        else if (_isCheckOutPhotoTaken)
                          const Icon(Icons.check_circle, color: Colors.white, size: 36)
                        else
                          const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          _isCheckingOut ? 'PROCESSING...' :
                          _isCheckOutPhotoTaken ? 'PHOTO TAKEN' : 'TAKE CHECK-OUT PHOTO',
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
            ),

            const SizedBox(height: 12),
            Text(
              _isCheckingOut
                  ? 'Completing check-out...'
                  : !_isCheckOutPhotoTaken
                  ? 'Tap to take check-out photo'
                  : 'Photo captured! Tap Check-out button below',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            // Check-out confirmation button (only shows after check-out photo is taken)
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    !_isCheckOutPhotoTaken ? 'Check-in Photo' : 'Check-out Photo',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                        Text('No photo', style: TextStyle(color: Colors.grey)),
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
            ),

            const SizedBox(height: 24),

            // Location Card
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
                            fontWeight: FontWeight.w600,
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
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
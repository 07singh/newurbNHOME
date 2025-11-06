// lib/models/plot_info.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

enum AreaUnit { sqYds, sqFt }
enum BookingStatus { available, pending, booked, sellout }

class PlotInfo {
  final String id;
  String area;
  AreaUnit areaUnit;
  double fare;
  double paidAmount;
  double totalAmount;
  String clientName;
  String? photoPath;
  double bookedArea;
  String projectName;
  double purchasePrice;
  double receivingAmount;
  double pendingAmount;
  String paidThrough;
  DateTime bookingDate;
  String bookedByDealer;
  String customerPhone;
  String dealerPhone;
  bool status;
  BookingStatus bookingStatus;
  String plotType;

  PlotInfo({
    required this.id,
    required this.area,
    this.areaUnit = AreaUnit.sqYds,
    required this.fare,
    this.paidAmount = 0,
    this.totalAmount = 0,
    this.clientName = '',
    this.photoPath,
    this.bookedArea = 0,
    required this.projectName,
    this.purchasePrice = 0,
    this.receivingAmount = 0,
    this.pendingAmount = 0,
    this.paidThrough = 'Online Transfer',
    DateTime? bookingDate,
    this.bookedByDealer = '',
    this.customerPhone = '',
    this.dealerPhone = '',
    this.status = true,
    this.bookingStatus = BookingStatus.available,
    required this.plotType,
  }) : bookingDate = bookingDate ?? DateTime.now() {
    totalAmount = fare * _parseArea(area, areaUnit);
  }

  double _parseArea(String area, AreaUnit unit) {
    final value = double.tryParse(area.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return unit == AreaUnit.sqFt ? value / 9 : value;
  }

  double get totalAreaValue => _parseArea(area, areaUnit);
  double get remainingArea => totalAreaValue - bookedArea;
  double get bookedPercentage => totalAreaValue > 0 ? bookedArea / totalAreaValue : 0;
  double get paidPercentage => totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;

  Color get color {
    switch (bookingStatus) {
      case BookingStatus.available:
        return Colors.green.shade200;
      case BookingStatus.pending:
        return paidPercentage < 50 ? Colors.red.shade300 : Colors.yellow.shade300;
      case BookingStatus.booked:
        return Colors.blue.shade300;
      case BookingStatus.sellout:
        return Colors.grey.shade300;
    }
  }

  String get statusText {
    switch (bookingStatus) {
      case BookingStatus.available:
        return "Available";
      case BookingStatus.pending:
        return paidPercentage < 50 ? "Pending (<50%)" : "Pending (≥50%)";
      case BookingStatus.booked:
        return "Booked";
      case BookingStatus.sellout:
        return "Sold Out";
    }
  }

  Map<String, dynamic> toJson() {
    final totalAreaValue = _parseArea(area, areaUnit);
    final remaining = (totalAreaValue - bookedArea).toString();

    String screenshot = photoPath ?? '';
    if (photoPath != null && File(photoPath!).existsSync()) {
      final bytes = File(photoPath!).readAsBytesSync();
      screenshot = base64Encode(bytes);
    }

    String statusStr;
    switch (bookingStatus) {
      case BookingStatus.available:
        statusStr = 'Available';
        break;
      case BookingStatus.pending:
        statusStr = 'Pending';
        break;
      case BookingStatus.booked:
        statusStr = 'Booked';
        break;
      case BookingStatus.sellout:
        statusStr = 'Sellout';
        break;
    }

    return {
      'Project_Name': projectName,
      'Purchase_price': purchasePrice.toString(),
      'Receiving_Amount': receivingAmount,
      'Pending_Amount': pendingAmount,
      'Paid_Through': paidThrough,
      'Booked_ByDealer': bookedByDealer,
      'Customer_Name': clientName,
      'Customer_Phn_Number': customerPhone,
      'Dealer_Phn_Number': dealerPhone,
      'Bookingdate': bookingDate.toIso8601String().split('T')[0],
      'Status': status,
      'Plot_Number': id,
      'Total_Area': totalAreaValue.toString(),
      'Booking_Area': bookedArea.toString(),
      'Screenshot': screenshot,
      'Total_Amount': totalAmount.toInt(),
      'Booking_Status': statusStr,
      'Plot_Type': plotType,
      'Remaining_Area': remaining,
    };
  }

  factory PlotInfo.fromJson(Map<String, dynamic> json) {
    final areaStr = json['Total_Area']?.toString() ?? '0';
    final unitStr = json['Area_Unit']?.toString() ?? 'Sq.Yds';
    final areaUnit = unitStr.contains('sq ft') ? AreaUnit.sqFt : AreaUnit.sqYds;

    final totalAreaValue = double.tryParse(areaStr) ?? 0;
    final bookedAreaValue = double.tryParse(json['Booking_Area']?.toString() ?? '0') ?? 0;
    final area = '$totalAreaValue ${areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'}';

    final totalAmount = (json['Total_Amount'] is num
        ? (json['Total_Amount'] as num).toDouble()
        : double.tryParse(json['Total_Amount']?.toString() ?? '0') ?? 0.0);
    final fare = totalAreaValue > 0 ? totalAmount / totalAreaValue : 0.0;

    final statusString = (json['Booking_Status'] as String?)?.toLowerCase();
    BookingStatus bookingStatus;
    switch (statusString) {
      case 'pending':
        bookingStatus = BookingStatus.pending;
        break;
      case 'booked':
        bookingStatus = BookingStatus.booked;
        break;
      case 'sellout':
        bookingStatus = BookingStatus.sellout;
        break;
      default:
        bookingStatus = BookingStatus.available;
    }

    return PlotInfo(
      id: json['Plot_Number']?.toString() ?? '',
      area: area,
      areaUnit: areaUnit,
      fare: fare,
      paidAmount: (json['Receiving_Amount'] is num
          ? (json['Receiving_Amount'] as num).toDouble()
          : double.tryParse(json['Receiving_Amount']?.toString() ?? '0') ?? 0.0),
      totalAmount: totalAmount,
      clientName: json['Customer_Name']?.toString() ?? '',
      photoPath: json['Screenshot']?.toString(),
      bookedArea: bookedAreaValue,
      projectName: json['Project_Name']?.toString() ?? 'Unknown',
      purchasePrice: (json['Purchase_price'] is num
          ? (json['Purchase_price'] as num).toDouble()
          : double.tryParse(json['Purchase_price']?.toString() ?? '0') ?? 0.0),
      receivingAmount: (json['Receiving_Amount'] is num
          ? (json['Receiving_Amount'] as num).toDouble()
          : double.tryParse(json['Receiving_Amount']?.toString() ?? '0') ?? 0.0),
      pendingAmount: (json['Pending_Amount'] is num
          ? (json['Pending_Amount'] as num).toDouble()
          : double.tryParse(json['Pending_Amount']?.toString() ?? '0') ?? 0.0),
      paidThrough: json['Paid_Through']?.toString() ?? 'Online Transfer',
      bookingDate: DateTime.tryParse(json['Bookingdate']?.toString() ?? '') ?? DateTime.now(),
      bookedByDealer: json['Booked_ByDealer']?.toString() ?? '',
      customerPhone: json['Customer_Phn_Number']?.toString() ?? '',
      dealerPhone: json['Dealer_Phn_Number']?.toString() ?? '',
      status: json['Status'] is bool ? json['Status'] as bool : true,
      bookingStatus: bookingStatus,
      plotType: json['Plot_Type']?.toString() ?? 'Unknown',
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

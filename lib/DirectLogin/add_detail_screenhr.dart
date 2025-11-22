import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/Model/add_history_screen.dart';

class DayBookDetailScreenhr extends StatelessWidget {
  final DayBookHistory entry;

  const DayBookDetailScreenhr({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = entry.dateTime != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(entry.dateTime!)
        : 'Unknown';

    Uint8List? screenshotBytes;
    String? screenshotUrl;

    if (entry.screenshot != null && entry.screenshot!.isNotEmpty) {
      final value = entry.screenshot!.trim();
      final isAbsoluteUrl = value.startsWith('http');
      final isRelativePath = value.startsWith('/');

      if (isAbsoluteUrl || isRelativePath) {
        screenshotUrl = isAbsoluteUrl ? value : "https://realapp.cheenu.in$value";
      } else {
        try {
          screenshotBytes = base64Decode(value);
        } catch (_) {
          screenshotBytes = null;
        }
      }
    }

    Widget screenshotSection;
    Widget failedImageWidget = Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade200,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.broken_image, color: Colors.redAccent, size: 48),
          SizedBox(height: 8),
          Text(
            "Failed to load image",
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (screenshotBytes != null || screenshotUrl != null) {
      screenshotSection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Screenshot:",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: screenshotBytes != null
                ? Image.memory(
              screenshotBytes,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Image.network(
              screenshotUrl!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => failedImageWidget,
            ),
          ),
        ],
      );
    } else {
      screenshotSection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Screenshot:",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            "No Screenshot Available",
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3371F4),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "${entry.employeeName ?? 'Employee'}'s Day Book",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff7F00FF),
                      Color(0xffE100FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.employeeName ?? 'Unknown Employee',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Payment Given By: ${entry.paymentGivenBy ?? '-'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Mode: ${entry.paymentMode ?? '-'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              buildDetailCard(
                icon: Icons.currency_rupee,
                title: "Amount",
                value: "₹ ${entry.amount?.toStringAsFixed(2) ?? '0'}",
              ),

              buildDetailCard(
                icon: Icons.description,
                title: "Purpose",
                value: entry.purpose ?? '-',
              ),

              buildDetailCard(
                icon: Icons.badge,
                title: "Payment Given By",
                value: entry.paymentGivenBy ?? '-',
              ),

              buildDetailCard(
                icon: Icons.person,
                title: "Spent By",
                value: entry.spendBy ?? '-',
              ),

              buildDetailCard(
                icon: Icons.account_balance_wallet,
                title: "Payment Mode",
                value: entry.paymentMode ?? '-',
              ),

              /// REMARKS
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.sticky_note_2,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    "Remarks",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entry.remarks ?? "No Remarks",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// SCREENSHOT
              screenshotSection,

              const SizedBox(height: 30),

              /// APPROVE / REJECT BUTTONS


            ],
          ),
        ),
      ),
    );
  }

  /// REUSABLE CARD
  Widget buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

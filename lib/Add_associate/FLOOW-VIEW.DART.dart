
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '/Model/follow_up_summary_model.dart';
import '/service/follow_up_service.dart';

class WeekFlowupPage extends StatefulWidget {
  @override
  State<WeekFlowupPage> createState() => _WeekFlowupPageState();
}

enum FollowUpFilter { today, thisWeek, thisMonth }

class _WeekFlowupPageState extends State<WeekFlowupPage> {
  final List<FollowUpSummary> _followUps = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  FollowUpFilter _filter = FollowUpFilter.today;
  bool _loading = false;
  String? _error;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final phone = await _storage.read(key: 'user_mobile');
    if (!mounted) return;
    setState(() {
      _userPhone = phone;
    });
    _fetchFollowUps();
  }

  Future<void> _updateFollowUp(FollowUpSummary summary) async {
    DateTime? selectedDate = summary.nextFollowUpDate ?? DateTime.now();
    final remarkController =
        TextEditingController(text: summary.lastRemark ?? "");

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Text(
                    "Update Follow-up",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(DateFormat('dd MMM yyyy').format(selectedDate ?? DateTime.now())),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 0)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: selectedDate ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: remarkController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Remark",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _submitFollowUpUpdate(
                          item: summary,
                          nextDate: selectedDate ?? DateTime.now(),
                          note: remarkController.text.trim(),
                        );
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFollowUpUpdate({
    required FollowUpSummary item,
    required DateTime? nextDate,
    required String note,
  }) async {
    if (_userPhone == null || _userPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User phone not available")),
        );
      }
      return;
    }

    final url = Uri.parse("https://realapp.cheenu.in/api/followup/add");
    final payload = {
      "FollowUp_Id": item.followUpId,
      "Client_Name": item.clientName,
      "Contact_No": item.contactNo,
      "Project_Name": item.projectName,
      "Next_FollowUp_Date": (nextDate ?? DateTime.now()).toIso8601String(),
      "Remark": note,
      "Created_By": _userPhone,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Follow-up updated successfully")),
          );
        }
        _fetchFollowUps();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update (${response.statusCode})")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating follow-up ($e)")),
        );
      }
    }
  }

  Future<void> _fetchFollowUps() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await FollowUpService.fetchFollowUpSummaryList();
      setState(() {
        _followUps
          ..clear()
          ..addAll(list);
      });
    } catch (e) {
      setState(() => _error = "Unable to load data ($e)");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "-";
    try {
      final date = DateTime.parse(isoString);
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Follow-up Summary"),
        backgroundColor: Color(0xFFFFD700),
        actions: [
          IconButton(
            onPressed: _fetchFollowUps,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : _followUps.isEmpty
            ? _buildEmpty()
            : Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error ?? "Something went wrong",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetchFollowUps,
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        "No follow-ups found.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: FollowUpFilter.values.map((filter) {
        final isActive = _filter == filter;
        return ChoiceChip(
          label: Text(_labelFor(filter)),
          selected: isActive,
          onSelected: (_) => setState(() => _filter = filter),
          selectedColor: Color(0xFFFFD700),
          labelStyle: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildList() {
    final filtered = _followUps.where(_matchesFilter).toList();
    if (filtered.isEmpty) {
      return _buildEmpty();
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final name = item.clientName.isNotEmpty ? item.clientName : "-";
        final contact = item.contactNo.isNotEmpty ? item.contactNo : "-";
        final project = item.projectName.isNotEmpty ? item.projectName : "-";
        final last = _formatDate(item.lastFollowUpDate?.toIso8601String());
        final next = _formatDate(item.nextFollowUpDate?.toIso8601String());
        final remark = item.lastRemark ?? "No note";
        final phone = item.contactNo;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text("ID #${item.followUpId}"),
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildRow("Contact", contact),
              _buildRow("Project", project),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(child: _buildDateColumn("Last Follow-up", last)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateColumn("Next Follow-up", next)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Note",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                remark,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: phone.isEmpty
                          ? null
                          : () => _callContact(phone),
                      icon: const Icon(Icons.phone),
                      label: const Text("Call"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateFollowUp(item),
                      icon: const Icon(Icons.edit),
                      label: const Text("Update"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _callContact(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    // ignore: deprecated_member_use
    if (await launchUrl(uri)) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to initiate call")),
      );
    }
  }

  bool _matchesFilter(FollowUpSummary item) {
    final DateTime? nextDate = item.nextFollowUpDate;
    if (nextDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_filter) {
      case FollowUpFilter.today:
        final nextDay = DateTime(nextDate.year, nextDate.month, nextDate.day);
        return nextDay == today;
      case FollowUpFilter.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return !nextDate.isBefore(startOfWeek) && !nextDate.isAfter(endOfWeek);
      case FollowUpFilter.thisMonth:
        return nextDate.year == today.year && nextDate.month == today.month;
    }
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(FollowUpFilter filter) {
    switch (filter) {
      case FollowUpFilter.today:
        return "Today";
      case FollowUpFilter.thisWeek:
        return "This Week";
      case FollowUpFilter.thisMonth:
        return "This Month";
    }
  }
}

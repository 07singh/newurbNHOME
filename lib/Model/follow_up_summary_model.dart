class FollowUpSummaryResponse {
  final String status;
  final int count;
  final List<FollowUpSummary> data;

  FollowUpSummaryResponse({
    required this.status,
    required this.count,
    required this.data,
  });

  factory FollowUpSummaryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList = json['Data'] ?? [];
    final List<FollowUpSummary> parsedList = rawList
        .whereType<Map>()
        .map((e) => FollowUpSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return FollowUpSummaryResponse(
      status: json['Status'] ?? '',
      count: json['Count'] ?? parsedList.length,
      data: parsedList,
    );
  }
}

class FollowUpSummary {
  final int followUpId;
  final String clientName;
  final String contactNo;
  final String projectName;
  final DateTime? lastFollowUpDate;
  final DateTime? nextFollowUpDate;
  final String? lastRemark;
  final DateTime? updatedOn;

  FollowUpSummary({
    required this.followUpId,
    required this.clientName,
    required this.contactNo,
    required this.projectName,
    this.lastFollowUpDate,
    this.nextFollowUpDate,
    this.lastRemark,
    this.updatedOn,
  });

  factory FollowUpSummary.fromJson(Map<String, dynamic> json) {
    DateTime? _tryParse(String? value) {
      if (value == null || value.isEmpty) return null;
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return FollowUpSummary(
      followUpId: json['FollowUp_Id'] ?? 0,
      clientName: json['Client_Name'] ?? '',
      contactNo: json['Contact_No'] ?? '',
      projectName: json['Project_Name'] ?? '',
      lastFollowUpDate: _tryParse(json['Last_FollowUp_Date']?.toString()),
      nextFollowUpDate: _tryParse(json['Next_FollowUp_Date']?.toString()),
      lastRemark: json['Last_Remark'],
      updatedOn: _tryParse(json['Updated_On']?.toString()),
    );
  }
}



import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '/Model/profile_model.dart';

class StaffProfileService {
  // ===================== UPDATE PROFILE PIC =====================
  Future<bool> updateProfilePicture({
    required String phone,
    required String position,
    File? file,
  }) async {
    // ✔ CORRECT API ENDPOINT (BACKEND SE CONFIRMED)
    var url = Uri.parse(
      "https://realapp.cheenu.in/Api/StaffChangeProfile/UpdateProfilePic",
    );

    var request = http.MultipartRequest("POST", url);

    // ✔ EXACT BACKEND FIELD NAMES
    request.fields["Phone"] = phone;
    request.fields["Position"] = position;

    // ✔ FILE FIELD EXACT NAME: "Profilepic"
    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "Profilepic",
          file.path,
        ),
      );
    }

    print("📤 FINAL FIELDS SENT: ${request.fields}");
    print("📤 FILE SENT: ${file?.path}");

    var response = await request.send();
    var body = await response.stream.bytesToString();

    print("📌 Profile Update Response: $body");

    var jsonData = jsonDecode(body);

    return jsonData["Status"] == "Success";
  }

  // ===================== FETCH PROFILE API =====================
  final String _baseUrl = "https://realapp.cheenu.in/Api/StaffProfile";

  Future<StaffProfileResponse> fetchProfile({
    required String phone,
    required String position,
  }) async {
    final uri = Uri.parse("$_baseUrl?Phone=$phone&Position=$position");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return StaffProfileResponse.fromJson(jsonResponse);
      } else {
        throw Exception("Failed to fetch profile: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching staff profile: $e");
    }
  }
}

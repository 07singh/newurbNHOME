import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AssociateService {
  static Future<Map<String, dynamic>> addAssociate({
    required Map<String, String> fields,
    File? aadharFront,
    File? aadharBack,
    File? panPic,
  }) async {
    var uri = Uri.parse("https://realapp.cheenu.in/api/associate/add");
    var request = http.MultipartRequest("POST", uri);

    // Add text fields
    request.fields.addAll(fields);

    // Add files
    if (aadharFront != null) {
      request.files.add(await http.MultipartFile.fromPath('AadharFront', aadharFront.path));
    }
    if (aadharBack != null) {
      request.files.add(await http.MultipartFile.fromPath('AadharBack', aadharBack.path));
    }
    if (panPic != null) {
      request.files.add(await http.MultipartFile.fromPath('PanPic', panPic.path));
    }

    var response = await request.send();
    var body = await response.stream.bytesToString();

    return {
      "status": response.statusCode,
      "body": jsonDecode(body),
    };
  }
}

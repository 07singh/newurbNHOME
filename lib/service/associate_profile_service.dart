import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/associate_profile_model.dart';

class AssociateProfileService {
  Future<AssociateProfile?> fetchProfile(String phone) async {
    final url = Uri.parse('https://realapp.cheenu.in/Api/AssociateProfile?Phone=$phone');
    
    print('🌐 Fetching profile from: $url');

    try {
      final response = await http.get(url);
      
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debug: Print the entire response
        print('📦 API Response: ${json.encode(data)}');
        
        if (data['message'] == 'Success' && data['data'] != null) {
          print('✅ Profile data found');
          
          // Debug: Print image URL from response
          final profileData = data['data'];
          print('🖼️ Image fields in response:');
          print('  - profileImageUrl: ${profileData['profileImageUrl']}');
          print('  - ProfileImageUrl: ${profileData['ProfileImageUrl']}');
          print('  - ProfilePic: ${profileData['ProfilePic']}');
          print('  - Profilepic: ${profileData['Profilepic']}');
          
          return AssociateProfile.fromJson(data['data']);
        } else {
          print('⚠️ No data or message not Success: ${data['message']}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in fetchProfile: $e');
    }
    
    return null;
  }
}

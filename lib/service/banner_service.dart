import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/banner_model.dart';

class BannerService {
  final String baseUrl = "https://realapp.cheenu.in";

  // GET banner images
  Future<BannerResponse?> getBannerImages() async {
    try {
      final url = "$baseUrl/Api/GetBannerImage";
      print('Fetching banners from: $url');
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');
        final bannerResponse = BannerResponse.fromJson(data);
        print('Banners count: ${bannerResponse.banners.length}');
        if (bannerResponse.banners.isNotEmpty) {
          var firstBanner = bannerResponse.banners.first;
          print('First banner - ID: ${firstBanner.id}');
          print('First banner - Image1: ${firstBanner.image1}');
          print('First banner - Image2: ${firstBanner.image2}');
          print('First banner - Image3: ${firstBanner.image3}');
        }
        return bannerResponse;
      } else {
        print('Failed to fetch banners. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching banner images: $e');
      return null;
    }
  }

  // POST add banner
  Future<bool> addBanner({
    required String image1,
    required String image2,
    required String image3,
  }) async {
    try {
      final url = "$baseUrl/api/banner/add";
      final body = json.encode({
        'Image1': image1,
        'Image2': image2,
        'Image3': image3,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding banner: $e');
      return false;
    }
  }

  // POST update banner
  Future<bool> updateBanner({
    required int id,
    required String image1,
    required String image2,
    required String image3,
  }) async {
    try {
      final url = "$baseUrl/api/banner/update";
      final body = json.encode({
        'Id': id,
        'Image1': image1,
        'Image2': image2,
        'Image3': image3,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error updating banner: $e');
      return false;
    }
  }
}


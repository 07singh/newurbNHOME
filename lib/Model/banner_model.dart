class BannerModel {
  final int? id;
  final String? image1;
  final String? image2;
  final String? image3;

  BannerModel({
    this.id,
    this.image1,
    this.image2,
    this.image3,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['ID'],
      image1: json['Image1'],
      image2: json['Image2'],
      image3: json['Image3'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'Id': id,
      'Image1': image1 ?? '',
      'Image2': image2 ?? '',
      'Image3': image3 ?? '',
    };
  }
}

class BannerResponse {
  final String message;
  final List<BannerModel> banners;

  BannerResponse({
    required this.message,
    required this.banners,
  });

  factory BannerResponse.fromJson(Map<String, dynamic> json) {
    List<BannerModel> bannerList = [];
    if (json['data1'] != null && json['data1'] is List) {
      bannerList = (json['data1'] as List)
          .map((item) => BannerModel.fromJson(item))
          .toList();
    }
    return BannerResponse(
      message: json['message'] ?? '',
      banners: bannerList,
    );
  }
}





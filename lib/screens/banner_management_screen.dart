import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../service/banner_service.dart';
import '../Model/banner_model.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final BannerService _bannerService = BannerService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _image1;
  File? _image2;
  File? _image3;
  
  String? _base64Image1;
  String? _base64Image2;
  String? _base64Image3;

  bool _isLoading = false;
  bool _isLoadingBanners = false;
  List<BannerModel> _existingBanners = [];
  BannerModel? _selectedBannerForUpdate;

  @override
  void initState() {
    super.initState();
    _loadExistingBanners();
  }

  Future<void> _loadExistingBanners() async {
    setState(() {
      _isLoadingBanners = true;
    });

    try {
      final response = await _bannerService.getBannerImages();
      if (response != null && response.banners.isNotEmpty) {
        setState(() {
          _existingBanners = response.banners;
        });
      }
    } catch (e) {
      print('Error loading banners: $e');
    } finally {
      setState(() {
        _isLoadingBanners = false;
      });
    }
  }

  Future<void> _pickImage(int imageNumber) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Compress the image
        final compressedFile = await _compressImage(File(pickedFile.path));
        if (compressedFile == null) {
          _showSnackBar('Failed to compress image', isError: true);
          return;
        }

        // Convert to base64
        final bytes = await compressedFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          if (imageNumber == 1) {
            _image1 = compressedFile;
            _base64Image1 = base64Image;
          } else if (imageNumber == 2) {
            _image2 = compressedFile;
            _base64Image2 = base64Image;
          } else if (imageNumber == 3) {
            _image3 = compressedFile;
            _base64Image3 = base64Image;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final targetPath = "${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 80,
        minWidth: 1920,
        minHeight: 1080,
      );
      return compressed != null ? File(compressed.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original if compression fails
    }
  }

  void _removeImage(int imageNumber) {
    setState(() {
      if (imageNumber == 1) {
        _image1 = null;
        _base64Image1 = null;
      } else if (imageNumber == 2) {
        _image2 = null;
        _base64Image2 = null;
      } else if (imageNumber == 3) {
        _image3 = null;
        _base64Image3 = null;
      }
    });
  }

  Future<void> _addBanner() async {
    if (_base64Image1 == null || _base64Image2 == null || _base64Image3 == null) {
      _showSnackBar('Please select all 3 images', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _bannerService.addBanner(
        image1: _base64Image1!,
        image2: _base64Image2!,
        image3: _base64Image3!,
      );

      if (success) {
        _showSnackBar('Banner added successfully!');
        _clearImages();
        _loadExistingBanners();
      } else {
        _showSnackBar('Failed to add banner', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBanner() async {
    if (_selectedBannerForUpdate == null) {
      _showSnackBar('Please select a banner to update', isError: true);
      return;
    }

    if (_base64Image1 == null || _base64Image2 == null || _base64Image3 == null) {
      _showSnackBar('Please select all 3 images', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _bannerService.updateBanner(
        id: _selectedBannerForUpdate!.id!,
        image1: _base64Image1!,
        image2: _base64Image2!,
        image3: _base64Image3!,
      );

      if (success) {
        _showSnackBar('Banner updated successfully!');
        _clearImages();
        _selectedBannerForUpdate = null;
        _loadExistingBanners();
      } else {
        _showSnackBar('Failed to update banner', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearImages() {
    setState(() {
      _image1 = null;
      _image2 = null;
      _image3 = null;
      _base64Image1 = null;
      _base64Image2 = null;
      _base64Image3 = null;
    });
  }

  void _loadBannerForUpdate(BannerModel banner) {
    setState(() {
      _selectedBannerForUpdate = banner;
      _image1 = null;
      _image2 = null;
      _image3 = null;
      _base64Image1 = null;
      _base64Image2 = null;
      _base64Image3 = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildImageSelector(String label, File? image, String? base64Image, int imageNumber) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (image != null || base64Image != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image != null
                      ? Image.file(
                          image,
                          fit: BoxFit.cover,
                        )
                      : _selectedBannerForUpdate != null
                          ? Image.network(
                              'https://realapp.cheenu.in${imageNumber == 1 ? _selectedBannerForUpdate!.image1 : imageNumber == 2 ? _selectedBannerForUpdate!.image2 : _selectedBannerForUpdate!.image3}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(Icons.image, size: 50),
                            ),
                ),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  color: Colors.grey.shade100,
                ),
                child: const Center(
                  child: Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(imageNumber),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Select Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (image != null || base64Image != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removeImage(imageNumber),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add/Update Banner Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBannerForUpdate == null ? 'Add New Banner' : 'Update Banner (ID: ${_selectedBannerForUpdate!.id})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildImageSelector('Image 1', _image1, _base64Image1, 1),
                    _buildImageSelector('Image 2', _image2, _base64Image2, 2),
                    _buildImageSelector('Image 3', _image3, _base64Image3, 3),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_selectedBannerForUpdate == null ? _addBanner : _updateBanner),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _selectedBannerForUpdate == null ? 'Add Banner' : 'Update Banner',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        if (_selectedBannerForUpdate != null) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedBannerForUpdate = null;
                                _clearImages();
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Existing Banners Section
            const Text(
              'Existing Banners',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingBanners)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_existingBanners.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No banners found'),
                  ),
                ),
              )
            else
              ..._existingBanners.map((banner) => Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Banner ID: ${banner.id}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _loadBannerForUpdate(banner),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Update'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildBannerPreview(
                                  banner.image1,
                                  'Image 1',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBannerPreview(
                                  banner.image2,
                                  'Image 2',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBannerPreview(
                                  banner.image3,
                                  'Image 3',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPreview(String? imagePath, String label) {
    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imagePath != null && imagePath.isNotEmpty
                ? Image.network(
                    'https://realapp.cheenu.in$imagePath',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 30),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  )
                : const Center(
                    child: Icon(Icons.image, size: 30, color: Colors.grey),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}





import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../service/banner_service.dart';
import '../Model/banner_model.dart';

class BannerManagementScreenhr extends StatefulWidget {
  const BannerManagementScreenhr({super.key});

  @override
  State<BannerManagementScreenhr> createState() => _BannerManagementScreenhrState();
}

class _BannerManagementScreenhrState extends State<BannerManagementScreenhr> {
  final BannerService _bannerService = BannerService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _image1;
  File? _image2;
  File? _image3;

  String? _base64Image1;
  String? _base64Image2;
  String? _base64Image3;

  bool _isLoading = false;
  bool _isFetchingBanner = false;
  BannerModel? _selectedBannerForUpdate;
  BannerModel? _currentBanner;
  bool _isUpdateMode = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBanner();
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

  Future<void> _submitBanner() async {
    if (_base64Image1 == null || _base64Image2 == null || _base64Image3 == null) {
      _showSnackBar('Please select all 3 images', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success;
      if (_isUpdateMode && _selectedBannerForUpdate != null) {
        success = await _bannerService.updateBanner(
          id: _selectedBannerForUpdate!.id!,
          image1: _base64Image1!,
          image2: _base64Image2!,
          image3: _base64Image3!,
        );
      } else {
        success = await _bannerService.addBanner(
          image1: _base64Image1!,
          image2: _base64Image2!,
          image3: _base64Image3!,
        );
      }

      if (success) {
        _showSnackBar(_isUpdateMode ? 'Banner updated successfully!' : 'Banner added successfully!');
        _clearImages(resetUpdateMode: true);
        await _fetchCurrentBanner();
      } else {
        _showSnackBar(_isUpdateMode ? 'Failed to update banner' : 'Failed to add banner', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearImages({bool resetUpdateMode = false}) {
    setState(() {
      _image1 = null;
      _image2 = null;
      _image3 = null;
      _base64Image1 = null;
      _base64Image2 = null;
      _base64Image3 = null;
      if (resetUpdateMode) {
        _selectedBannerForUpdate = null;
        _isUpdateMode = false;
      }
    });
  }

  Future<void> _loadBannerForUpdate() async {
    setState(() {
      _isFetchingBanner = true;
    });

    try {
      final response = await _bannerService.getBannerImages();
      if (response != null && response.banners.isNotEmpty) {
        setState(() {
          _currentBanner = response.banners.first;
          _selectedBannerForUpdate = _currentBanner;
          _isUpdateMode = true;
          _image1 = null;
          _image2 = null;
          _image3 = null;
          _base64Image1 = null;
          _base64Image2 = null;
          _base64Image3 = null;
        });
        _showSnackBar('Loaded existing banner. Select images and tap Add Banner to update.');
      } else {
        _showSnackBar('No banner found to update', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to load banner: $e', isError: true);
    } finally {
      setState(() {
        _isFetchingBanner = false;
      });
    }
  }

  Future<void> _fetchCurrentBanner() async {
    setState(() {
      _isFetchingBanner = true;
    });
    try {
      final response = await _bannerService.getBannerImages();
      if (response != null && response.banners.isNotEmpty) {
        setState(() {
          _currentBanner = response.banners.first;
        });
      } else {
        setState(() {
          _currentBanner = null;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load current banner: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingBanner = false;
        });
      }
    }
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
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 50),
                    ),
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
                      backgroundColor: Colors.blue,
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

  Widget _buildCurrentBannerPreview() {
    if (_isFetchingBanner && _currentBanner == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Banner Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_currentBanner == null)
              const Text(
                'No banner uploaded yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: [
                  _buildPreviewImage('Image 1', _currentBanner!.image1),
                  _buildPreviewImage('Image 2', _currentBanner!.image2),
                  _buildPreviewImage('Image 3', _currentBanner!.image3),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImage(String title, String? path) {
    final imageUrl = (path ?? '').isEmpty ? null : 'https://realapp.cheenu.in$path';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: imageUrl == null
                ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
                : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner Management'),
        backgroundColor: Colors.blue,
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
                      _isUpdateMode && _selectedBannerForUpdate?.id != null
                          ? 'Update Banner (ID: ${_selectedBannerForUpdate!.id})'
                          : 'Add New Banner',
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitBanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
                          _isUpdateMode ? 'Add Banner (Update)' : 'Add Banner',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_isUpdateMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => _clearImages(resetUpdateMode: true),
                          child: const Text('Cancel Update'),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: _isFetchingBanner || _isLoading ? null : _loadBannerForUpdate,
                        icon: _isFetchingBanner
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.update),
                        label: const Text('Update Existing Banner'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCurrentBannerPreview(),
          ],
        ),
      ),
    );
  }
}







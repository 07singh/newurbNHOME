// lib/utils/image_utils.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Utility class for image operations including base64 conversion
class ImageUtils {
  /// Maximum file size in bytes (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;
  
  /// Default image quality for compression (0-100)
  static const int defaultQuality = 85;
  

  /// Convert image file to base64 string
  /// 
  /// [imageFile] - The image file to convert
  /// [compress] - Whether to compress the image before encoding (default: true)
  /// [quality] - Compression quality 0-100 (default: 85). Lower values = smaller file size
  /// 
  /// Returns base64 encoded string, or null if conversion fails
  /// Throws [Exception] if file doesn't exist or is too large
  static Future<String?> imageToBase64(
    File imageFile, {
    bool compress = true,
    int quality = defaultQuality,
  }) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSize && !compress) {
        throw Exception('Image size (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB) exceeds maximum allowed size (5MB). Please compress the image.');
      }

      File? fileToEncode = imageFile;

      // Compress image if requested
      if (compress) {
        try {
          fileToEncode = await _compressImage(
            imageFile,
            quality: quality,
          );
          
          if (fileToEncode == null) {
            // If compression fails, use original file
            print('⚠️ Image compression failed, using original file');
            fileToEncode = imageFile;
          } else {
            // Check compressed file size
            final compressedSize = await fileToEncode.length();
            print('✅ Image compressed: ${(fileSize / 1024).toStringAsFixed(2)}KB → ${(compressedSize / 1024).toStringAsFixed(2)}KB');
          }
        } catch (e) {
          print('⚠️ Compression error: $e, using original file');
          fileToEncode = imageFile;
        }
      }

      // Read file bytes
      final bytes = await fileToEncode.readAsBytes();
      
      // Check final size
      if (bytes.length > maxFileSize) {
        throw Exception('Image is too large even after compression. Please select a smaller image.');
      }

      // Encode to base64
      final base64String = base64Encode(bytes);
      
      print('✅ Image converted to base64: ${(base64String.length / 1024).toStringAsFixed(2)}KB');
      
      return base64String;
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      rethrow;
    }
  }

  /// Compress image file
  /// 
  /// [quality] - Compression quality 0-100 (default: 85)
  /// 
  /// Returns compressed file path, or null if compression fails
  static Future<File?> _compressImage(
    File imageFile, {
    int quality = defaultQuality,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = imageFile.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/compressed_$timestamp$fileName';

      // Compress image
      // Note: flutter_image_compress 2.1.0 only supports quality parameter
      // For size control, we rely on quality setting
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
      
      return null;
    } catch (e) {
      print('❌ Image compression error: $e');
      return null;
    }
  }

  /// Convert base64 string back to image file (for testing/debugging)
  /// 
  /// [base64String] - Base64 encoded string
  /// [outputPath] - Path where to save the decoded image
  /// 
  /// Returns the decoded image file
  static Future<File> base64ToImage(String base64String, String outputPath) async {
    try {
      final bytes = base64Decode(base64String);
      final file = File(outputPath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw Exception('Failed to decode base64 to image: $e');
    }
  }

  /// Get image file size in MB
  static Future<double> getFileSizeMB(File imageFile) async {
    try {
      final size = await imageFile.length();
      return size / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  /// Validate image file
  /// 
  /// Returns true if file is valid, throws Exception if not
  static Future<bool> validateImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }

    final fileSize = await imageFile.length();
    if (fileSize == 0) {
      throw Exception('Image file is empty');
    }

    if (fileSize > maxFileSize) {
      throw Exception('Image size (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB) exceeds maximum allowed size (5MB)');
    }

    return true;
  }
}


import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class AvatarService {
  /// Convert image file to Base64 string for Firestore storage
  /// Compresses image to reduce Firestore document size
  static Future<String?> imageToBase64(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Tệp ảnh không tồn tại');
      }

      // Read image bytes
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image to compress it
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Không thể đọc ảnh');
      }

      // Resize image to max 300x300 to reduce size
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: 300,
        height: 300,
        maintainAspect: true,
      );

      // Encode as JPEG with quality 80
      Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 80),
      );

      // Check compressed size (Firestore has 1MB limit per document)
      if (compressedBytes.length > 800 * 1024) {
        // 800KB limit for safety
        throw Exception('Ảnh quá lớn sau khi nén. Vui lòng chọn ảnh khác.');
      }

      // Convert to Base64
      String base64String = base64Encode(compressedBytes);

      print('Ảnh gốc: ${imageBytes.length / 1024} KB');
      print('Ảnh nén: ${compressedBytes.length / 1024} KB');
      print('Base64 length: ${base64String.length}');

      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Lỗi chuyển ảnh sang Base64: $e');
      return null;
    }
  }

  /// Convert Base64 string to Image widget
  static Widget? base64ToImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }

    try {
      // Remove data:image/jpeg;base64, prefix if exists
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:image')) {
        cleanBase64 = base64String.split(',')[1];
      }

      // Decode Base64 to bytes
      Uint8List bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Lỗi hiển thị ảnh Base64: $error');
          return Icon(Icons.error, color: Colors.red);
        },
      );
    } catch (e) {
      print('Lỗi decode Base64: $e');
      return Icon(Icons.error, color: Colors.red);
    }
  }

  /// Get image size from Base64 string
  static double getBase64ImageSize(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:image')) {
        cleanBase64 = base64String.split(',')[1];
      }

      // Base64 encoding increases size by ~33%
      double sizeInBytes = (cleanBase64.length * 3) / 4;
      return sizeInBytes / 1024; // Return size in KB
    } catch (e) {
      return 0;
    }
  }

  /// Validate if Base64 string is valid image
  static bool isValidBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }

    try {
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:image')) {
        cleanBase64 = base64String.split(',')[1];
      }

      Uint8List bytes = base64Decode(cleanBase64);
      img.Image? image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }
}

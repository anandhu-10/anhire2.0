import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  /// Uploads PDF bytes directly to Cloudinary using unsigned upload preset and returns the secure URL.
  Future<String> uploadPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'resume_uploads';
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'resume_uploads';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
    debugPrint("Uploading PDF '$fileName' to Cloudinary URL: $uri with preset: $uploadPreset");

    try {
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = jsonResponse['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          debugPrint("Cloudinary upload successful! Secure URL: $secureUrl");
          return secureUrl;
        }
      }

      debugPrint("Cloudinary upload failed with status ${response.statusCode}: ${response.body}");
      throw Exception("Cloudinary upload failed (${response.statusCode}): ${response.body}");
    } catch (e, st) {
      debugPrint("CloudinaryService.uploadPdf error: $e\n$st");
      rethrow;
    }
  }
}

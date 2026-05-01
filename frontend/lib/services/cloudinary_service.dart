import 'dart:io';

import 'package:dio/dio.dart';

class CloudinaryService {
  Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    required Map<String, dynamic> signedParams,
  }) async {
    final cloudName = signedParams['cloud_name'] as String;
    final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      'api_key': signedParams['api_key'],
      'timestamp': signedParams['timestamp'].toString(),
      'signature': signedParams['signature'],
      'folder': signedParams['folder'],
      'tags': (signedParams['tags'] as List).join(','),
    });

    final response = await Dio().post(
      uploadUrl,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    final data = response.data as Map<String, dynamic>;
    return {
      'cloudinary_url': data['secure_url'] ?? data['url'],
      'cloudinary_public_id': data['public_id'],
    };
  }
}

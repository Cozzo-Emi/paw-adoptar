import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  Future<Map<String, dynamic>> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    required Map<String, dynamic> signedParams,
  }) async {
    final cloudName = signedParams['cloud_name'] as String;
    final uploadUrl =
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes, 
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ),
      'api_key': signedParams['api_key'],
      'timestamp': signedParams['timestamp'].toString(),
      'signature': signedParams['signature'],
      'folder': signedParams['folder'],
      'tags': (signedParams['tags'] as List).join(','),
    });

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    final response = await dio.post(
      uploadUrl,
      data: formData,
    );

    final data = response.data as Map<String, dynamic>;
    return {
      'cloudinary_url': data['secure_url'] ?? data['url'],
      'cloudinary_public_id': data['public_id'],
    };
  }
}

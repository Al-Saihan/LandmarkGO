import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/landmark.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';
  static const String imageBaseUrl = 'https://labs.anontech.info/cse489/t3/';

  // ! GET: Retrieve all landmarks
  // ! Returns a list of Landmark objects
  static Future<List<Landmark>> getAllLandmarks() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
      );

      if (response.statusCode == 200) {
        // ? Decode JSON response and convert to List<Landmark>
        final List<dynamic> jsonList = _parseJsonResponse(response.body);
        return jsonList.map((json) => Landmark.fromJson(json as Map<String, dynamic>, imageBaseUrl)).toList();
      } else {
        throw Exception('Failed to load landmarks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching landmarks: $e');
    }
  }

  // ! POST: Create a new landmark
  // ! Returns the created Landmark with its ID assigned by the server
  static Future<Landmark> createLandmark({
    required String title,
    required double lat,
    required double lon,
    required String image,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: _encodeJsonBody({
          'title': title,
          'lat': lat,
          'lon': lon,
          'image': image,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = _parseJsonResponse(response.body);
        return Landmark.fromJson(jsonResponse as Map<String, dynamic>, imageBaseUrl);
      } else {
        throw Exception('Failed to create landmark: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating landmark: $e');
    }
  }

  // ! POST (Multipart): Create entity with image file upload
  static Future<int> createLandmarkWithImage({
    required String title,
    required double lat,
    required double lon,
    required List<int> imageBytes,
    String filename = 'upload.jpg',
  }) async {
    try {
      final uri = Uri.parse(baseUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['title'] = title
        ..fields['lat'] = lat.toString()
        ..fields['lon'] = lon.toString();

      // Attach image bytes with explicit JPEG content type
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = _parseJsonResponse(response.body);
        // Expecting JSON with created id, e.g., {"id": 123} or {"id": "123"}
        if (data is Map<String, dynamic> && data.containsKey('id')) {
          final dynamic rawId = data['id'];
          if (rawId is num) return rawId.toInt();
          if (rawId is String) {
            final parsed = int.tryParse(rawId);
            if (parsed != null) return parsed;
          }
          throw Exception('Invalid id type: ${data['id'].runtimeType}');
        }
        throw Exception('Unexpected response format: ${response.body}');
      } else {
        throw Exception('Failed to create landmark: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating landmark with image: $e');
    }
  }

  // ! PUT: Update an existing landmark
  // ! Returns the updated Landmark object
  static Future<Landmark> updateLandmark({
    required int id,
    required String title,
    required double lat,
    required double lon,
    required String image,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: _encodeJsonBody({
          'id': id,
          'title': title,
          'lat': lat,
          'lon': lon,
          'image': image,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = _parseJsonResponse(response.body);
        return Landmark.fromJson(jsonResponse as Map<String, dynamic>, imageBaseUrl);
      } else {
        throw Exception('Failed to update landmark: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating landmark: $e');
    }
  }

  // ! PUT: Update entity using x-www-form-urlencoded (no image)
  static Future<bool> updateLandmarkForm({
    required int id,
    required String title,
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'id': id.toString(),
          'title': title,
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
      throw Exception('Failed to update (form): ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error updating (form): $e');
    }
  }

  // ! PUT (Multipart): Update entity with optional image
  static Future<bool> updateLandmarkMultipart({
    required int id,
    required String title,
    required double lat,
    required double lon,
    List<int>? imageBytes,
    String? filename,
  }) async {
    try {
      final uri = Uri.parse(baseUrl);
      final request = http.MultipartRequest('PUT', uri)
        ..fields['id'] = id.toString()
        ..fields['title'] = title
        ..fields['lat'] = lat.toString()
        ..fields['lon'] = lon.toString();
      if (imageBytes != null && filename != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        return true;
      }
      throw Exception('Failed to update (multipart): ${resp.statusCode} ${resp.body}');
    } catch (e) {
      throw Exception('Error updating (multipart): $e');
    }
  }

  // ! DELETE: Remove a landmark by ID
  // ! Returns true if deletion was successful
  static Future<bool> deleteLandmark(int id) async {
    debugPrint('Deleting landmark with id: $id || $baseUrl?id=$id');
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl?id=$id'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete landmark: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting landmark: $e');
    }
  }

  // ? Helper: Parse JSON response (handles both single object and array)
  static dynamic _parseJsonResponse(String body) {
    try {
      return jsonDecode(body);
    } catch (e) {
      throw Exception('Failed to parse JSON response: $e');
    }
  }

  // ? Helper: Encode request body to JSON
  static String _encodeJsonBody(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      throw Exception('Failed to encode JSON body: $e');
    }
  }
}



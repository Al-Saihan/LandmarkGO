import 'package:http/http.dart' as http;
import '../models/landmark.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';

  // ! GET: Retrieve all landmarks
  // ! Returns a list of Landmark objects
  static Future<List<Landmark>> getAllLandmarks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/landmarks'),
      );

      if (response.statusCode == 200) {
        // ? Decode JSON response and convert to List<Landmark>
        final List<dynamic> jsonList = _parseJsonResponse(response.body);
        return jsonList.map((json) => Landmark.fromJson(json)).toList();
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
        Uri.parse('$baseUrl/landmarks'),
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
        return Landmark.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to create landmark: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating landmark: $e');
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
        Uri.parse('$baseUrl/landmarks/$id'),
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
        return Landmark.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to update landmark: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating landmark: $e');
    }
  }

  // ! DELETE: Remove a landmark by ID
  // ! Returns true if deletion was successful
  static Future<bool> deleteLandmark(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/landmarks/$id'),
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



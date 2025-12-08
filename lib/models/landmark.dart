import 'dart:convert';

class Landmark {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String image;

  Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.image,
  });

  // ? Convert Landmark to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
    };
  }

  // ? Create Landmark from JSON (null-safe and type-tolerant)
  factory Landmark.fromJson(Map<String, dynamic> json, [String imageBase = '']) {
    final dynamic rawTitle = json['title'];
    final dynamic rawLat = json['lat'];
    final dynamic rawLon = json['lon'];
    final dynamic rawImage = json['image'];

    String title = (rawTitle is String) ? rawTitle : rawTitle?.toString() ?? '';
    double lat = _toDouble(rawLat);
    double lon = _toDouble(rawLon);
    String imagePath = (rawImage is String) ? rawImage : '';

    if (imageBase.isNotEmpty && imagePath.isNotEmpty && !imagePath.startsWith('http')) {
      imagePath = imageBase + imagePath;
    }

    return Landmark(
      id: (json['id'] as num).toInt(),
      title: title,
      lat: lat,
      lon: lon,
      image: imagePath,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v) ?? 0.0;
    }
    return 0.0;
  }

  // ? Create Landmark from JSON string
  factory Landmark.fromJsonString(String jsonString) {
    return Landmark.fromJson(jsonDecode(jsonString));
  }

  // ? Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  @override
  String toString() {
    return 'Landmark(id: $id, title: $title, lat: $lat, lon: $lon, image: $image)';
  }
}

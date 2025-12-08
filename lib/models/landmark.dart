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

  // ? Create Landmark from JSON
  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['id'] as int,
      title: json['title'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      image: json['image'] as String,
    );
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

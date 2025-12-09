import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../services/api_service.dart';
import '../models/landmark.dart';
import '../includes/globals.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late final MapController _mapController;
  final GeoPoint _initPoint = GeoPoint(latitude: 23.6850, longitude: 90.3563);
  List<Landmark> _landmarks = [];
  bool _markersApplied = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController(initPosition: _initPoint);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarkers();
    });
  }

  Future<void> _loadMarkers() async {
    try {
      final data = await ApiService.getAllLandmarks();
      _landmarks = data;

      try {
        await _mapController.removeMarker(_initPoint);
      } catch (_) {}

      // ignore: deprecated_member_use
      await _mapController.changeLocation(_initPoint);
      await _mapController.setZoom(zoomLevel: 16);

      await _applyMarkersWithTheme();
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_landmarks.isNotEmpty) {
        _applyMarkersWithTheme();
      }
    });
  }

  Future<void> _applyMarkersWithTheme() async {
    if (_landmarks.isEmpty) return;

    final cs = Theme.of(context).colorScheme;

    try {
      // Fallback: remove existing markers by their known coordinates
      for (final lm in _landmarks) {
        try {
          await _mapController.removeMarker(
            GeoPoint(latitude: lm.lat, longitude: lm.lon),
          );
        } catch (_) {}
      }
    } catch (_) {}

    for (final lm in _landmarks) {
      await _mapController.addMarker(
        GeoPoint(latitude: lm.lat, longitude: lm.lon),
        markerIcon: MarkerIcon(
          iconWidget: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorSelectedItem, width: 6),
              boxShadow: [
                BoxShadow(
                  color: colorBackground.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              size: 90,
              color: colorUnselectedItem,
            ),
          ),
        ),
      );
    }

    _markersApplied = true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OSMFlutter(
      controller: _mapController,
      osmOption: OSMOption(
        zoomOption: const ZoomOption(
          initZoom: 16,
          minZoomLevel: 3,
          maxZoomLevel: 19,
        ),
        enableRotationByGesture: false,
        roadConfiguration: RoadOption(roadColor: cs.primary.withAlpha(60)),
      ),
    );
  }
}

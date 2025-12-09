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
  // ignore: unused_field
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

    // ignore: unused_local_variable
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

    final futures = _landmarks.map((lm) => 
      _mapController.addMarker(
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
      ),
    );
    await Future.wait(futures);

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
      onGeoPointClicked: (GeoPoint p) {
        final lm = _landmarks.firstWhere(
          (e) =>
              e.lat.toStringAsFixed(6) == p.latitude.toStringAsFixed(6) &&
              e.lon.toStringAsFixed(6) == p.longitude.toStringAsFixed(6),
          orElse: () => Landmark(
            id: -1,
            title: 'Unknown',
            lat: p.latitude,
            lon: p.longitude,
            image: '',
          ),
        );
        _showLandmarkSheet(context, lm);
      },
    );
  }

  void _showLandmarkSheet(BuildContext context, Landmark lm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.25,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview left
              SizedBox(
                width: 120,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: lm.image.isEmpty
                      ? Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 32,
                          ),
                        )
                      : Image.network(lm.image, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              // Info + actions right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lm.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text('Lat: ${lm.lat.toStringAsFixed(6)}'),
                    Text('Lon: ${lm.lon.toStringAsFixed(6)}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: lm.id < 0
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _showQuickEditDialog(context, lm);
                                },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: lm.id < 0
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  final ok = await ApiService.deleteLandmark(
                                    lm.id,
                                  );
                                  if (ok) {
                                    setState(() {
                                      _landmarks.removeWhere(
                                        (e) => e.id == lm.id,
                                      );
                                    });
                                    await _applyMarkersWithTheme();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Landmark deleted'),
                                        ),
                                      );
                                    }
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Delete failed'),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuickEditDialog(BuildContext context, Landmark lm) async {
    final titleController = TextEditingController(text: lm.title);
    final latController = TextEditingController(text: lm.lat.toString());
    final lonController = TextEditingController(text: lm.lon.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Landmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lonController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final newTitle = titleController.text.trim();
      final newLat = double.tryParse(latController.text.trim());
      final newLon = double.tryParse(lonController.text.trim());
      if (newTitle.isEmpty || newLat == null || newLon == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Provide valid title/lat/lon')),
          );
        }
        return;
      }
      try {
        final ok = await ApiService.updateLandmarkForm(
          id: lm.id,
          title: newTitle,
          lat: newLat,
          lon: newLon,
        );
        if (ok) {
          setState(() {
            final index = _landmarks.indexWhere((e) => e.id == lm.id);
            if (index >= 0) {
              _landmarks[index] = Landmark(
                id: lm.id,
                title: newTitle,
                lat: newLat,
                lon: newLon,
                image: lm.image,
              );
            }
          });
          await _applyMarkersWithTheme();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Updated successfully')),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Update failed')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

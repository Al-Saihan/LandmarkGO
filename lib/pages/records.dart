import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../services/api_service.dart';
import '../includes/globals.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late Future<List<Landmark>> _landmarksFuture;
  // ignore: unused_field
  List<Landmark> _cachedLandmarks = [];

  @override
  void initState() {
    super.initState();
    _loadLandmarks();
  }

  void _loadLandmarks() {
    _landmarksFuture = ApiService.getAllLandmarks().then((landmarks) {
      _cachedLandmarks = landmarks;
      return landmarks;
    });
  }

  void _refreshLandmarks() {
    setState(() {
      _loadLandmarks();
    });
  }

  void _deleteLandmark(int id) async {
    try {
      await ApiService.deleteLandmark(id);
      _refreshLandmarks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Landmark deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting landmark: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Landmark>>(
      future: _landmarksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshLandmarks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No landmarks found'));
        }

        final landmarks = snapshot.data!;
        return _buildLandmarksList(landmarks);
      },
    );
  }

  Widget _buildLandmarksList(List<Landmark> landmarks) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: landmarks.length,
      itemBuilder: (context, index) {
        return LandmarkCard(
          landmark: landmarks[index],
          onDelete: _deleteLandmark,
        );
      },
      cacheExtent: 400,
    );
  }
}

class LandmarkCard extends StatefulWidget {
  final Landmark landmark;
  final Function(int) onDelete;

  const LandmarkCard({
    super.key,
    required this.landmark,
    required this.onDelete,
  });

  @override
  State<LandmarkCard> createState() => _LandmarkCardState();
}

class _LandmarkCardState extends State<LandmarkCard> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkTheme,
      builder: (context, isDark, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: ValueKey('landmark-${widget.landmark.id}'),
            direction: DismissDirection.horizontal,
            background: _buildSlideBackground(
              alignment: Alignment.centerLeft,
              color: const Color.fromARGB(255, 150, 121, 99),
              icon: Icons.edit,
              label: 'Edit',
            ),
            secondaryBackground: _buildSlideBackground(
              alignment: Alignment.centerRight,
              color: const Color.fromARGB(255, 118, 38, 12),
              icon: Icons.delete,
              label: 'Delete',
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Edit on left swipe
                _onEdit();
                return false; // Do not dismiss the card
              } else {
                // Delete on right swipe
                final confirmed = await _confirmDelete(context);
                if (confirmed) {
                  widget.onDelete(widget.landmark.id);
                }
                return false; // Keep card; list refresh will reflect deletion
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: colorBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorTitle, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(55),
                    blurRadius: 8,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Left side: Info
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.landmark.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorSelectedItem,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${widget.landmark.lat.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorUnselectedItem,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lon: ${widget.landmark.lon.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorUnselectedItem,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right side: Image preview
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade300,
                      ),
                      child: _buildImageWidget(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlideBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignment,
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }

  void _onEdit() {
    // Placeholder for edit flow – navigate to edit screen or open dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit action')));
  }

  Widget _buildImageWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: widget.landmark.image.isEmpty
          ? const Center(child: Icon(Icons.image_not_supported))
          : Image.network(
              widget.landmark.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_not_supported,
                        size: 32,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No Image',
                        style: TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Landmark'),
        content: Text(
          'Are you sure you want to delete "${widget.landmark.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

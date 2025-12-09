import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/landmark.dart';

class NewEntryPage extends StatefulWidget {
  final int? editId;
  final String? initialTitle;
  final double? initialLat;
  final double? initialLon;

  const NewEntryPage({
    super.key,
    this.editId,
    this.initialTitle,
    this.initialLat,
    this.initialLon,
  });

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  Set<String> _selectedSegment = {'add'};
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  XFile? _pickedImage;
  bool _submitting = false;
  List<Landmark> _landmarks = [];
  int? _editId; // internal edit id to use for updates

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _selectedSegment = {'edit'};
    }
    _editId = widget.editId;
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialLat != null) {
      _latController.text = widget.initialLat!.toString();
    }
    if (widget.initialLon != null) {
      _lonController.text = widget.initialLon!.toString();
    }
    _loadLandmarksForSelection();
    // Auto-fill current GPS location when adding a new entry
    if (widget.editId == null) {
      _prefillCurrentLocation();
    }
  }

  Future<void> _loadLandmarksForSelection() async {
    try {
      final items = await ApiService.getAllLandmarks();
      if (mounted) {
        setState(() => _landmarks = items);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 20),

          SegmentedButton<String>(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primary;
                }
                return Theme.of(context).colorScheme.surface;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.onPrimary;
                }
                return Theme.of(context).colorScheme.onSurface;
              }),
            ),
            segments: const [
              ButtonSegment<String>(
                value: 'add',
                label: Text('Add Entry'),
                icon: Icon(Icons.add),
              ),
              ButtonSegment<String>(
                value: 'edit',
                label: Text('Edit Entry'),
                icon: Icon(Icons.edit),
              ),
            ],
            selected: _selectedSegment,
            multiSelectionEnabled: false,
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedSegment = newSelection;
                _resetFormForSegment();
              });
            },
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ! Upload Image
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Stack(
                            children: [
                              if (_pickedImage == null)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 48,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _selectedSegment.contains('add')
                                            ? 'Tap to upload image'
                                            : 'Cannot Change Image In Edit Mode\n(Add a New Entry Instead)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_pickedImage!.path),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (_selectedSegment.contains('add'))
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Wrap(
                                    spacing: 8,
                                    children: [
                                      if (_pickedImage != null)
                                        OutlinedButton.icon(
                                          onPressed: _submitting
                                              ? null
                                              : () => setState(
                                                  () => _pickedImage = null,
                                                ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: const Text('Remove'),
                                        ),
                                    ],
                                  ),
                                ),
                              // Make whole container tappable to pick image in Add mode
                              if (_selectedSegment.contains('add'))
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _submitting ? null : _pickImage,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ! Select Landmark (only in edit mode)
                        if (_selectedSegment.contains('edit'))
                          GestureDetector(
                            onTap: _showLandmarkPicker,
                            child: AbsorbPointer(
                              absorbing: true,
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: _titleController.text,
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Select Landmark (tap to choose)',
                                  suffixIcon: const Icon(Icons.arrow_drop_down),
                                  labelStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  floatingLabelAlignment:
                                      FloatingLabelAlignment.center,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // ! Title (separate editable input)
                        TextFormField(
                          controller: _titleController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            floatingLabelAlignment:
                                FloatingLabelAlignment.center,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ! Enter Latitude
                        TextFormField(
                          controller: _latController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Enter Latitude',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            floatingLabelAlignment:
                                FloatingLabelAlignment.center,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        // ! Enter Longitude
                        TextFormField(
                          controller: _lonController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Enter Longitude',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            floatingLabelAlignment:
                                FloatingLabelAlignment.center,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _submitting ? null : _submit,
                          child: Text(
                            _selectedSegment.contains('add')
                                ? 'Add Landmark'
                                : 'Save Landmark',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _prefillCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (mounted) {
        if (_latController.text.trim().isEmpty) {
          _latController.text = pos.latitude.toString();
        }
        if (_lonController.text.trim().isEmpty) {
          _lonController.text = pos.longitude.toString();
        }
      }
    } catch (_) {
      // silently ignore; user can fill manually
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _submit() async {
    try {
      final title = _titleController.text.trim();
      final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
      final lon = double.tryParse(_lonController.text.trim()) ?? 0.0;
      if (title.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Title is required')));
        return;
      }
      setState(() => _submitting = true);
      if (_selectedSegment.contains('add')) {
        if (_pickedImage == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please pick an image')));
          setState(() => _submitting = false);
          return;
        }
        final resizedBytes = await _resizeToJpeg(
          _pickedImage!.path,
          800,
          600,
          quality: 85,
        );
        final createdId = await ApiService.createLandmarkWithImage(
          title: title,
          lat: lat,
          lon: lon,
          imageBytes: resizedBytes,
          filename: 'landmark_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created entity with id $createdId')),
          );
        }
      } else {
        // Edit flow: choose form or multipart based on image presence
        final id = _editId;
        if (id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing entry id for edit')),
          );
          setState(() => _submitting = false);
          return;
        }
        // In edit mode, do not allow changing the image; update metadata only
        final ok = await ApiService.updateLandmarkForm(
          id: id,
          title: title,
          lat: lat,
          lon: lon,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? 'Updated successfully' : 'Update failed'),
            ),
          );
        }
      }
      setState(() => _submitting = false);
      // Optionally clear form
      _titleController.clear();
      _latController.clear();
      _lonController.clear();
      setState(() => _pickedImage = null);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<List<int>> _resizeToJpeg(
    String path,
    int targetW,
    int targetH, {
    int quality = 85,
  }) async {
    final fileBytes = await File(path).readAsBytes();
    final original = img.decodeImage(fileBytes);
    if (original == null) {
      throw Exception('Unable to decode image');
    }
    // Fit to 800x600, cover keeps aspect while filling target size
    final resized = img.copyResize(original, width: targetW, height: targetH);
    return img.encodeJpg(resized, quality: quality);
  }

  Future<void> _showLandmarkPicker() async {
    if (_landmarks.isEmpty) {
      await _loadLandmarksForSelection();
      if (_landmarks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No landmarks available')),
          );
        }
        return;
      }
    }
    final selected = await showDialog<Landmark>(
      context: mounted ? context : context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Landmark'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _landmarks.length,
              itemBuilder: (context, index) {
                final lm = _landmarks[index];
                return ListTile(
                  title: Text(lm.title),
                  subtitle: Text(
                    'Lat: ${lm.lat.toStringAsFixed(4)}, Lon: ${lm.lon.toStringAsFixed(4)}',
                  ),
                  onTap: () => Navigator.of(context).pop(lm),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      setState(() {
        _editId = selected.id;
        _titleController.text = selected.title;
        _latController.text = selected.lat.toString();
        _lonController.text = selected.lon.toString();
      });
      if (selected.image.isNotEmpty) {
        await _setPickedImageFromUrl(selected.image);
      }
      // Keep selection separate; user edits title in its own field
    }
  }

  void _resetFormForSegment() {
    // Clear inputs when switching between add/edit to avoid stale data
    _titleController.clear();
    _latController.clear();
    _lonController.clear();
    setState(() => _pickedImage = null);
    _editId = _selectedSegment.contains('edit') ? _editId : null;
    if (_selectedSegment.contains('add')) {
      // Re-prefill GPS for add
      _prefillCurrentLocation();
    }
  }

  Future<void> _setPickedImageFromUrl(String url) async {
    try {
      // Download image bytes and store in a temp file so Image.file can preview
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final List<int> bytes = [];
        await for (var data in response) {
          bytes.addAll(data);
        }
        final tempDir = Directory.systemTemp;
        final filePath =
            '${tempDir.path}/lm_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final f = File(filePath);
        await f.writeAsBytes(bytes);
        setState(() => _pickedImage = XFile(filePath));
      }
      client.close();
    } catch (_) {
      // Ignore failures; user can still pick/change image
    }
  }
}

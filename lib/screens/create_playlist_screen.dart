import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../providers/playlist_provider.dart';

class CreatePlaylistScreen extends StatefulWidget {
  final Playlist? playlist; // null for create, non-null for edit

  const CreatePlaylistScreen({super.key, this.playlist});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _imageUrl;
  bool _isPublic = false;
  bool _isLoading = false;

  bool get isEditing => widget.playlist != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.playlist!.name;
      _descriptionController.text = widget.playlist!.description;
      _imageUrl = widget.playlist!.imageUrl;
      _isPublic = widget.playlist!.isPublic;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Playlist' : 'Create New Playlist'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePlaylist,
            child: Text(
              isEditing ? 'Save' : 'Create',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[300],
                      border: Border.all(
                        color: Colors.grey[400]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImagePlaceholder();
                              },
                            ),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: Text(
                    _imageUrl != null
                        ? 'Change Cover Image'
                        : 'Add Cover Image',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Name',
                  hintText: 'Enter your playlist name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter playlist name';
                  }
                  if (value.trim().length < 2) {
                    return 'Playlist name must be at least 2 characters';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter a description for your playlist (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 16),

              // Privacy Setting
              Card(
                child: SwitchListTile(
                  title: const Text('Public Playlist'),
                  subtitle: Text(
                    _isPublic
                        ? 'Anyone can find and listen to this playlist'
                        : 'Only you can listen to this playlist',
                  ),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Create/Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlaylist,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Playlist',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          'Add Cover Image',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  void _pickImage() {
    // TODO: Implement image picker
    // For now, just show a dialog to enter URL
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Cover Image'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter image URL...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (url) {
            Navigator.pop(context);
            if (url.isNotEmpty) {
              setState(() {
                _imageUrl = url;
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _imageUrl = null;
              });
            },
            child: const Text('Remove Image'),
          ),
        ],
      ),
    );
  }

  void _savePlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final playlistProvider = context.read<PlaylistProvider>();

      if (isEditing) {
        print('🔄 Updating playlist: ${widget.playlist!.id}');

        // Update existing playlist
        final updatedPlaylist = Playlist(
          id: widget.playlist!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          userFirebaseUid: widget.playlist!.userFirebaseUid,
          trackIds: widget.playlist!.trackIds,
          imageUrl: _imageUrl,
          createdAt: widget.playlist!.createdAt,
          updatedAt: DateTime.now(),
          isPublic: _isPublic,
        );

        final success = await playlistProvider.updatePlaylist(updatedPlaylist);
        print('✅ Update result: $success');

        if (!success) {
          throw Exception('Failed to update playlist');
        }
      } else {
        print('🔄 Creating new playlist');

        // Create new playlist
        final success = await playlistProvider.createPlaylist(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isPublic: _isPublic,
        );

        if (!success) {
          throw Exception('Failed to create playlist');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Playlist updated successfully!'
                  : 'Playlist created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('❌ Error saving playlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

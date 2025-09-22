import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../services/avatar_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
  bool _removeAvatar = false; // Track if user wants to remove avatar
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user != null) {
      _nameController.text = user.name;
    }

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user != null) {
      final hasNameChanged = _nameController.text != user.name;
      final hasImageChanged = _selectedImage != null;
      final hasAvatarRemoved = _removeAvatar;

      setState(() {
        _hasChanges = hasNameChanged || hasImageChanged || hasAvatarRemoved;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: primaryColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textPrimary),
                  onPressed: () => _handleBackPress(),
                ),
                title: Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  if (_hasChanges && !_isLoading)
                    TextButton(
                      onPressed: () => _saveProfile(auth),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor,
                          ),
                        ),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor.withOpacity(0.3), primaryColor],
                      ),
                    ),
                  ),
                ),
              ),

              // Profile Form Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildAvatarSection(auth),
                    const SizedBox(height: 32),
                    _buildProfileForm(),
                    const SizedBox(height: 32),
                    _buildActionButtons(auth),
                    const SizedBox(height: 100), // Space for mini player
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(AuthProvider auth) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: cardColor,
                child: _buildAvatarImage(auth),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _showImagePicker(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Tap camera to change avatar',
          style: TextStyle(color: textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(AuthProvider auth) {
    if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (_removeAvatar) {
      // Show default avatar when user wants to remove current avatar
      return _buildDefaultAvatar(auth);
    } else if (auth.user?.avatarUrl != null &&
        auth.user!.avatarUrl!.isNotEmpty) {
      // Check if it's Base64 or network URL
      if (auth.user!.avatarUrl!.startsWith('data:image')) {
        // Base64 image
        final base64Image = AvatarService.base64ToImage(auth.user!.avatarUrl!);
        if (base64Image != null) {
          return ClipOval(
            child: SizedBox(width: 120, height: 120, child: base64Image),
          );
        } else {
          return _buildDefaultAvatar(auth);
        }
      } else {
        // Network URL (old Firebase Storage URLs)
        return ClipOval(
          child: Image.network(
            auth.user!.avatarUrl!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(auth);
            },
          ),
        );
      }
    } else {
      return _buildDefaultAvatar(auth);
    }
  }

  Widget _buildDefaultAvatar(AuthProvider auth) {
    final initial = auth.user?.name.isNotEmpty == true
        ? auth.user!.name[0].toUpperCase()
        : 'U';

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.7)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Name Field
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name cannot be empty';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Info about email
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Email cannot be changed for security reasons. Contact support if needed.',
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? cardColor : cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? textPrimary : textSecondary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(
            color: enabled ? textSecondary : textSecondary.withOpacity(0.5),
          ),
          hintStyle: TextStyle(
            color: textSecondary.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? accentColor : textSecondary.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          errorStyle: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider auth) {
    return Column(
      children: [
        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _hasChanges && !_isLoading
                ? () => _saveProfile(auth)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasChanges ? accentColor : cardColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _hasChanges ? 8 : 0,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Text(
                    _hasChanges ? 'Save Changes' : 'No Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _hasChanges ? Colors.white : textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _handleBackPress(),
            style: OutlinedButton.styleFrom(
              foregroundColor: textSecondary,
              side: BorderSide(color: textSecondary.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = auth.user;
      if (currentUser == null) {
        throw Exception('User not found');
      }

      String? newAvatarUrl = currentUser.avatarUrl;

      // Handle avatar changes
      if (_selectedImage != null) {
        // Upload new avatar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Đang xử lý ảnh...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );

        // Convert image to Base64 for Firestore storage
        newAvatarUrl = await AvatarService.imageToBase64(_selectedImage!);

        if (newAvatarUrl == null) {
          throw Exception('Không thể xử lý ảnh. Vui lòng chọn ảnh khác.');
        }

        print(
          'Avatar chuyển Base64 thành công: ${AvatarService.getBase64ImageSize(newAvatarUrl)} KB',
        );

        // No need to delete old avatar since it's stored in Firestore
      } else if (_removeAvatar) {
        // Remove current avatar (just set to null)
        newAvatarUrl = null;
      }

      // Create updated user model
      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        avatarUrl: newAvatarUrl,
        updatedAt: DateTime.now(),
      );

      // Update profile
      final success = await auth.updateProfile(updatedUser);

      if (success) {
        _showSuccessSnackBar('Cập nhật hồ sơ thành công!');
        setState(() {
          _hasChanges = false;
          _selectedImage = null; // Clear selected image after successful upload
          _removeAvatar = false; // Reset remove flag
        });
        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate changes were saved
        }
      } else {
        throw Exception(auth.errorMessage ?? 'Không thể cập nhật hồ sơ');
      }
    } catch (e) {
      _showErrorSnackBar(
        'Lỗi cập nhật hồ sơ: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change Profile Picture',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImagePickerOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImagePickerOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null ||
                _removeAvatar ||
                Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).user?.avatarUrl !=
                    null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildImagePickerOption(
                  icon: Icons.delete_outline,
                  label: 'Remove Picture',
                  onTap: () => _removeImage(),
                  color: Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (color ?? accentColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? accentColor).withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color ?? accentColor, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color ?? accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _removeAvatar = false; // Reset remove flag when new image is selected
        });
        _onFieldChanged();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      // If user had an avatar URL, this means they want to remove their current avatar
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user?.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty) {
        _removeAvatar = true; // Mark for removal
      }
    });
    _onFieldChanged();
  }

  void _handleBackPress() {
    if (_hasChanges) {
      _showDiscardChangesDialog();
    } else {
      Navigator.pop(context);
    }
  }

  void _showDiscardChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Discard Changes?', style: TextStyle(color: textPrimary)),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close edit screen
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

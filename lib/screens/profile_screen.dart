import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/avatar_service.dart';
import 'edit_profile_screen.dart';
import 'favorite_screen.dart';
import 'listening_history_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: primaryColor,
      body: auth.isAuthenticated
          ? _buildAuthenticatedProfile(context, auth)
          : _buildUnauthenticatedProfile(context),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, AuthProvider auth) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        return CustomScrollView(
          slivers: [
            // App Bar with gradient
            SliverAppBar(
              expandedHeight: 260, // Reduced from 280
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentColor.withOpacity(0.8), primaryColor],
                    ),
                  ),
                  child: _buildProfileHeader(auth),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, color: textPrimary),
                  onPressed: () => _showSettingsDialog(context, auth),
                ),
              ],
            ),

            // Profile Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsSection(context, playlistProvider),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, auth),
                  const SizedBox(height: 24),
                  _buildAccountSection(context, auth),
                  const SizedBox(height: 100), // Space for mini player
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(AuthProvider auth) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar with music note decoration
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50, // Reduced from 60
                    backgroundColor: cardColor,
                    child: auth.user?.avatarUrl != null
                        ? ClipOval(child: _buildAvatarImage(auth))
                        : _buildDefaultAvatar(auth),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(6), // Reduced from 8
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 16, // Reduced from 20
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced from 16
            // User name
            Text(
              auth.user?.name ?? 'Music Lover',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22, // Reduced from 24
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // User email
            Text(
              auth.user?.email ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14, // Reduced from 16
              ),
            ),
            const SizedBox(height: 6), // Reduced from 8
            // Membership badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 14,
                  ), // Reduced from 16
                  const SizedBox(width: 4),
                  Text(
                    'Premium Member',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11, // Reduced from 12
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(AuthProvider auth) {
    if (auth.user?.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty) {
      // Check if it's Base64 or network URL
      if (auth.user!.avatarUrl!.startsWith('data:image')) {
        // Base64 image
        final base64Image = AvatarService.base64ToImage(auth.user!.avatarUrl!);
        if (base64Image != null) {
          return SizedBox(width: 100, height: 100, child: base64Image);
        } else {
          return _buildDefaultAvatar(auth);
        }
      } else {
        // Network URL (old Firebase Storage URLs)
        return Image.network(
          auth.user!.avatarUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(auth);
          },
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
      width: 100, // Reduced from 120
      height: 100, // Reduced from 120
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
            fontSize: 40, // Reduced from 48
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    PlaylistProvider playlistProvider,
  ) {
    final playlistCount = playlistProvider.playlists.length;
    final totalTracks = playlistProvider.playlists.fold<int>(
      0,
      (sum, playlist) => sum + playlist.trackCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Music statistics',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.queue_music,
                title: 'Playlists',
                value: playlistCount.toString(),
                color: accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.music_note,
                title: 'Songs',
                value: totalTracks.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AuthProvider auth) {
    final actions = [
      {
        'icon': Icons.edit,
        'title': 'Edit Profile',
        'subtitle': 'Update your personal information',
        'color': Colors.blue,
        'onTap': () => _navigateToEditProfile(context, auth),
      },
      {
        'icon': Icons.favorite,
        'title': 'Favorite Songs',
        'subtitle': 'View your favorite songs',
        'color': Colors.red,
        'onTap': () => _navigateToFavorites(context),
      },
      {
        'icon': Icons.history,
        'title': 'Listening History',
        'subtitle': 'Recently played songs',
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ListeningHistoryScreen(),
            ),
          );
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) => _buildActionTile(action)),
      ],
    );
  }

  Widget _buildActionTile(Map<String, dynamic> action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          decoration: BoxDecoration(
            color: action['color'].withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(action['icon'], color: action['color'], size: 24),
        ),
        title: Text(
          action['title'],
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          action['subtitle'],
          style: TextStyle(color: textSecondary),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: textSecondary, size: 16),
        onTap: action['onTap'],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.logout, color: Colors.red, size: 24),
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Log out of the current account',
                  style: TextStyle(color: textSecondary),
                ),
                onTap: () => _showLogoutDialog(context, auth),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: const Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Welcome to Music Player',
              style: TextStyle(
                color: textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Text(
              'Login to fully experience your features and store playlist',
              style: TextStyle(color: textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Register Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );

    // If profile was updated, you could refresh data here if needed
    if (result == true) {
      // Profile was successfully updated
      // Any additional refresh logic can be added here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSettingsDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Settings', style: TextStyle(color: textPrimary)),
        content: Text(
          'The settings feature will be updated in the next version.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  void _navigateToFavorites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoriteScreen()),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Logout', style: TextStyle(color: textPrimary)),
        content: Text(
          'Are you sure you want to log out of this account?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Reset player first (stop music and clear queue)
              final playerProvider = context.read<PlayerProvider>();
              await playerProvider.reset();

              // Then logout
              auth.logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

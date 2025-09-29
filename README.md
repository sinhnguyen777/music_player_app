# 🎵 Music Player App

A feature-rich music streaming application built with Flutter, Firebase, and SoundCloud API integration.

## 🚀 Overview

This is a comprehensive music player application that allows users to stream music, create playlists, manage their music library, and enjoy seamless playback experience across different platforms.

## ✨ Features

### 🎧 Core Music Features
- **Music Streaming**: Stream music from SoundCloud API
- **Audio Playback**: High-quality audio playback with controls (play, pause, skip, shuffle, repeat)
- **Queue Management**: Add, remove, and reorder tracks in playback queue
- **Background Playback**: Continue listening while using other apps
- **Seeking**: Jump to any position in the track
- **Volume Control**: Adjust playback volume

### 📱 User Interface
- **Modern UI**: Clean and intuitive material design interface
- **Dark/Light Theme**: Adaptive theme support
- **Responsive Design**: Works on phones, tablets, and different screen sizes
- **Smooth Animations**: Fluid transitions and interactive elements
- **Now Playing Screen**: Full-screen player with album artwork and controls

### 📚 Playlist Management
- **Create Playlists**: Build custom playlists with your favorite tracks
- **Edit Playlists**: Add/remove tracks, rename playlists, change covers
- **Personal Library**: Organize your music collection
- **Playlist Sharing**: Share your playlists with other users
- **Smart Recommendations**: Discover new music based on your preferences

### 👤 User Features
- **User Authentication**: Secure login and registration with Firebase Auth
- **User Profiles**: Personalized user profiles with avatar and preferences
- **Listening History**: Track your recently played songs
- **Favorites**: Mark tracks and playlists as favorites
- **Cross-device Sync**: Access your music library across all devices

### 🔍 Discovery Features
- **Search**: Find tracks, artists, and playlists quickly
- **Browse Categories**: Explore music by genre, mood, or popularity
- **Trending Music**: Discover what's popular right now
- **Personalized Feed**: Get music recommendations tailored to your taste

## 🛠 Technology Stack

- **Framework**: Flutter 3.x
- **Programming Language**: Dart
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Music API**: SoundCloud API for streaming
- **State Management**: Provider pattern
- **Audio Processing**: Just Audio package
- **UI Components**: Material Design widgets
- **Image Handling**: Cached Network Image
- **Local Storage**: Shared Preferences

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ✅ Web (Chrome, Safari, Firefox)
- ✅ macOS (10.14+)
- ✅ Windows (Windows 10+)
- ✅ Linux (Ubuntu 18.04+)

## 🚀 Getting Started

### Prerequisites

Before running this project, make sure you have:

- **Flutter SDK** (3.0 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control
- **Firebase CLI** for Firebase setup
- **SoundCloud Developer Account** for API access

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/sinhnguyen777/music_player_app.git
   cd music_player_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication and Firestore Database
   - Download `google-services.json` for Android and place in `android/app/`
   - Download `GoogleService-Info.plist` for iOS and place in `ios/Runner/`
   - Configure Firebase for web in `web/index.html`

4. **SoundCloud API Setup**
   - Create a SoundCloud developer account
   - Get your client ID and add it to your environment variables
   - Configure API endpoints in the app

5. **Configure environment variables**
   - Create `.env` file in the root directory
   - Add your API keys and configuration:
     ```
     SOUNDCLOUD_CLIENT_ID=your_soundcloud_client_id
     FIREBASE_WEB_API_KEY=your_firebase_web_api_key
     ```

### Running the App

1. **Check Flutter installation**
   ```bash
   flutter doctor
   ```

2. **Run on different platforms**
   ```bash
   # Android/iOS (with device connected or emulator running)
   flutter run
   
   # Web
   flutter run -d chrome
   
   # Windows
   flutter run -d windows
   
   # macOS
   flutter run -d macos
   
   # Linux
   flutter run -d linux
   ```

### Building for Production

1. **Android APK**
   ```bash
   flutter build apk --release
   ```

2. **Android App Bundle (recommended for Play Store)**
   ```bash
   flutter build appbundle --release
   ```

3. **iOS**
   ```bash
   flutter build ios --release
   ```

4. **Web**
   ```bash
   flutter build web --release
   ```

5. **Desktop platforms**
   ```bash
   # Windows
   flutter build windows --release
   
   # macOS
   flutter build macos --release
   
   # Linux
   flutter build linux --release
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── track.dart           # Track model
│   ├── playlist.dart        # Playlist model
│   ├── user.dart           # User model
│   └── queue_item.dart     # Queue item model
├── screens/                 # UI screens
│   ├── home_screen.dart    # Home/dashboard screen
│   ├── player_screen.dart  # Now playing screen
│   ├── playlist_detail_screen.dart  # Playlist details
│   ├── search_screen.dart  # Search functionality
│   ├── profile_screen.dart # User profile
│   └── auth/               # Authentication screens
├── providers/              # State management
│   ├── player_provider.dart    # Audio player state
│   ├── playlist_provider.dart  # Playlist management
│   ├── auth_provider.dart      # Authentication state
│   └── theme_provider.dart     # Theme management
├── services/               # Business logic & APIs
│   ├── firebase_auth_service.dart      # Authentication
│   ├── firebase_playlist_service.dart  # Playlist operations
│   ├── soundcloud_service.dart         # Music streaming
│   └── audio_service.dart              # Audio playback
├── widgets/                # Reusable UI components
│   ├── player_controls.dart    # Playback controls
│   ├── track_tile.dart        # Track list item
│   ├── playlist_card.dart     # Playlist preview
│   └── loading_indicator.dart # Loading states
└── utils/                  # Utilities & helpers
    ├── constants.dart      # App constants
    ├── themes.dart        # App themes
    └── helpers.dart       # Helper functions
```

## 🎯 Usage Guide

### Creating Playlists
1. Navigate to the Library tab
2. Tap "Create New Playlist"
3. Add a name and description
4. Start adding tracks from search or browse

### Adding Music
1. Use the search function to find tracks
2. Tap the "+" button next to any track
3. Select the playlist to add to
4. Enjoy your curated music collection

### Playing Music
1. Tap any track to start playback
2. Use the mini-player for basic controls
3. Tap the mini-player to open full player screen
4. Access queue, shuffle, and repeat options

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Write meaningful commit messages
- Add comments for complex logic
- Test your changes thoroughly
- Update documentation when needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

If you encounter any issues or have questions:

- 📧 Email: sinhnguyen777@example.com
- 💬 GitHub Issues: [Create an issue](https://github.com/sinhnguyen777/music_player_app/issues)
- 📚 Documentation: Check the wiki for detailed guides

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- SoundCloud for music streaming API
- Material Design for UI guidelines
- Open source community for valuable packages

## 📊 Project Status

- ✅ Core music playback functionality
- ✅ Playlist management
- ✅ User authentication
- ✅ Search and discovery
- ✅ Cross-platform support
- 🔄 Advanced audio features (in development)
- 📋 Social features (planned)

---

**Built with ❤️ using Flutter**

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'firebase_options_secure.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/listening_history_provider.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'screens/home_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize JustAudioBackground for notifications with platform check
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      await JustAudioBackground.init(
        androidNotificationChannelId:
            'com.example.music_player_app.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationChannelDescription: 'Music player controls',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      );
      print('JustAudioBackground initialized successfully');
    }
  } catch (e) {
    print('Failed to initialize JustAudioBackground: $e');
    // Continue without background audio - app won't crash
  }

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with secure options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO: Initialize AudioService later after fixing issues
  // final audioHandler = await AudioService.init(
  //   builder: () => MusicAudioHandler(),
  //   config: const AudioServiceConfig(
  //     androidNotificationChannelId:
  //         'com.example.music_player_app.channel.audio',
  //     androidNotificationChannelName: 'Music Playback',
  //     androidNotificationChannelDescription: 'Music player controls',
  //     androidNotificationOngoing: true,
  //     androidStopForegroundOnPause: true,
  //   ),
  // );

  runApp(const MyApp());
}

const Color primaryColor = Color(0xFF1A1A1A);
const Color accentColor = Color(0xFF6C5CE7);
const Color cardColor = Color(0xFF2A2A2A);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFB0B0B0);

class MyApp extends StatefulWidget {
  // TODO: Add audioHandler back when AudioService is fixed
  // final MusicAudioHandler audioHandler;

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // All providers restored with fixes
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()..init()),
        ChangeNotifierProvider(create: (_) => HomeProvider()..init()),
        ChangeNotifierProvider(create: (_) => ListeningHistoryProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PlaylistProvider>(
          create: (context) => PlaylistProvider(null),
          update: (context, auth, previous) {
            // Always create a new PlaylistProvider when auth changes
            print(
              'PlaylistProvider update - Auth: ${auth.isAuthenticated}, User: ${auth.user?.name}',
            );
            return PlaylistProvider(auth);
          },
        ),
      ],
      child: MaterialApp(
        title: 'SoundCloud Music',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: primaryColor,
          colorScheme: ColorScheme.dark(
            primary: accentColor,
            secondary: accentColor,
            surface: cardColor,
            background: primaryColor,
            onPrimary: textPrimary,
            onSecondary: textPrimary,
            onSurface: textPrimary,
            onBackground: textPrimary,
          ),
          useMaterial3: true,
          brightness: Brightness.dark,
          appBarTheme: AppBarTheme(
            backgroundColor: primaryColor,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: textPrimary),
          ),
          cardTheme: CardThemeData(
            color: cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: cardColor,
            selectedItemColor: accentColor,
            unselectedItemColor: textSecondary,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: primaryColor,
          appBarTheme: AppBarTheme(backgroundColor: primaryColor, elevation: 0),
        ),
        themeMode: _themeMode,
        home: const MainNav(),
      ),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;
  final _pages = [
    const HomeScreen(),
    const PlaylistsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_index],
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(children: [MiniPlayer()]),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: accentColor,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

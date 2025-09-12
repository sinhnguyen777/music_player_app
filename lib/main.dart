import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/player_provider.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

const Color primaryGreen = Color(0xFF1B5E20);

class MyApp extends StatefulWidget {
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
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()..init()),
        ChangeNotifierProvider(create: (_) => HomeProvider()..init()),
      ],
      child: MaterialApp(
        title: 'SoundCloud Music',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: primaryGreen,
          colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
          useMaterial3: true,
          brightness: Brightness.light,
          appBarTheme: const AppBarTheme(backgroundColor: primaryGreen),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primaryGreen,
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: primaryGreen,
          appBarTheme: const AppBarTheme(backgroundColor: primaryGreen),
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
  final _pages = const [HomeScreen(), SearchScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: primaryGreen,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

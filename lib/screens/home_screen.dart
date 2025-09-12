import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../widgets/section_carousel.dart';
import '../widgets/mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<HomeProvider>(context, listen: false).fetchAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = Provider.of<HomeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () =>
            Provider.of<HomeProvider>(context, listen: false).fetchAll(),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SectionCarousel(title: '🔥 Hot', tracks: home.hot),
            const SizedBox(height: 12),
            SectionCarousel(title: '📈 Trending', tracks: home.trending),
            const SizedBox(height: 12),
            SectionCarousel(title: '🆕 Latest', tracks: home.latest),
            const SizedBox(height: 12),
            SectionCarousel(title: '⭐ Recommended', tracks: home.recommended),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomSheet: const MiniPlayer(),
    );
  }
}

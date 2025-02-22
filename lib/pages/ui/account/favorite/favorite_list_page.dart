import 'package:appbook/pages/ui/account/favorite/list_fav_audio_page.dart';
import 'package:appbook/pages/ui/account/favorite/list_fav_comic_page.dart';
import 'package:appbook/pages/ui/account/favorite/list_fav_video_page.dart';
import 'package:flutter/material.dart';

class FavoriteListPage extends StatefulWidget {
  const FavoriteListPage({super.key});

  @override
  State<FavoriteListPage> createState() => _FavoriteListPageState();
}

class _FavoriteListPageState extends State<FavoriteListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'Danh sách yêu thích',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Truyện tranh'),
          Tab(text: 'Kể chuyện'),
          Tab(text: 'Hoạt hình'),
      ],
      ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ListComicPage(),
          ListAudioPage(),
          ListVideoPage(),
        ]
        ),
    );
  }
}

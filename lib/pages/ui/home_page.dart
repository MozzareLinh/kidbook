import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'comic/comic_page.dart';
import 'audio/audio_page.dart';
import 'dictionary/views/dictionary_page.dart';
import 'video/video_list_page.dart';
import 'account/account_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _selectedIndex = 0;

  // Hàm chuyển màn hình
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Các pages
    final List<Widget> pages = [
      const ComicPage(),
      const AudioPage(),
      const VideoListPage(),
      const DictionaryPage(),
      const AccountPage(),
    ];

    return Scaffold(
      body: Center(
        child: pages[_selectedIndex], // Hiển thị page tương ứng
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        iconSize: 24.0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.bookOpenReader),
            label: 'Truyện tranh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volume_up),
            label: 'Kể chuyện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_collection),
            label: 'Hoạt hình',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.unity),
            label: '3D',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

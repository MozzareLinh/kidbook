import 'package:appbook/pages/ui/video/gol/gol_page.dart';
import 'package:flutter/material.dart';

import 'story/story_page.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSearchBar = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40.0,
        title: _showSearchBar
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập tên truyện',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text(
                'Hoạt hình',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            onPressed: _toggleSearchBar,
            icon: Icon(
              _showSearchBar ? Icons.close : Icons.search,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Kể chuyện'),
            Tab(text: 'Quà tặng cuộc sống'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StoryPage(tab: 'Tab1', searchQuery: _searchQuery),
          GOLPage(tab: 'Tab2', searchQuery: _searchQuery),
        ],
      ),
    );
  }
}

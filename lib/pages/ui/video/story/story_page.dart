import 'package:appbook/pages/ui/video/story/play_story_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoryPage extends StatelessWidget {
  final String tab;
  final String searchQuery;

  const StoryPage({
    super.key,
    required this.tab,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('stories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Không có dữ liệu'),
          );
        }

        final stories = snapshot.data!.docs.where((story) {
          final title = (story['title'] as String).toLowerCase();
          return title.contains(searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final storyData = stories[index];
            return Story(
              storyId: stories[index].id,
              title: storyData['title'],
              thumbnailUrl: storyData['thumbnailUrl'],
              source: storyData['source'],
              duration: Duration(seconds: storyData['duration'] as int),
            );
          },
        );
      },
    );
  }
}

class Story extends StatelessWidget {
  final String storyId;
  final String title;
  final String thumbnailUrl;
  final String source;
  final Duration duration;

  const Story({
    super.key,
    required this.storyId,
    required this.title,
    required this.thumbnailUrl,
    required this.source,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayStoryPage(
                storyId: storyId,
                source: source,
                title: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 30.0,
            horizontal: 20.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  //Hình ảnh thu nhỏ của story
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      width: 260, // Chiếm toàn bộ chiều rộng
                      height: 180, // Chiều cao tùy chỉnh
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        image: DecorationImage(
                          image: NetworkImage(thumbnailUrl),
                          fit: BoxFit.fill, // Để đảm bảo hình ảnh đầy đủ
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 60.0,
                    height: 60.0,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        color: Colors.white,
                        iconSize: 40.0,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayStoryPage(
                                storyId: storyId,
                                source: source,
                                title: title,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ));
  }
}
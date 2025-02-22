import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'play_gol_page.dart';

class GOLPage extends StatelessWidget {
  final String tab;
  final String searchQuery;

  const GOLPage({
    super.key,
    required this.tab,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return  StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gols').snapshots(),
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

        final gols = snapshot.data!.docs.where((gol) {
          final title = (gol['title'] as String).toLowerCase();
          return title.contains(searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: gols.length,
          itemBuilder: (context, index) {
            final golData = gols[index];
            return GOL(
              golId: gols[index].id,
              title: golData['title'],
              thumbnailUrl: golData['thumbnailUrl'],
              source: golData['source'],
              duration: Duration(seconds: golData['duration'] as int),
            );
          },
        );
      },
    );
  }
}

class GOL extends StatelessWidget {
  final String golId;
  final String title;
  final String thumbnailUrl;
  final String source;
  final Duration duration;

  const GOL({
    super.key,
    required this.golId,
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
              builder: (context) => PlayGOLPage(
                golId: golId,
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
                              builder: (context) => PlayGOLPage(
                                golId: golId,
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
        ),
        );
  }
}

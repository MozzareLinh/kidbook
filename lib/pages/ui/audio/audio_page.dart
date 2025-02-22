import 'package:appbook/pages/ui/audio/play_audio_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key}); // Cập nhật constructor

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  // Biến hiển thị ô tìm kiếm
  bool isSearching = false;
  String searchQuery = '';

  // Danh sách toàn bộ audio từ Firestore
  late Stream<QuerySnapshot> _audioStream;

  @override
  void initState() {
    super.initState();
    _fetchAudioList();
  }

  void _fetchAudioList() {
    // Tạo stream từ Firestore
    _audioStream = FirebaseFirestore.instance.collection('audios').snapshots();
  }

  // Hàm lọc danh sách audio theo từ khóa
  void _filterAudioList(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !isSearching
            ? const Text(
                'Kể chuyện cho bé',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : TextField(
                onChanged: _filterAudioList, // Cập nhật từ khóa tìm kiếm
                decoration: InputDecoration(
                  hintText: 'Nhập tên truyện',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                autofocus: true,
              ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchQuery = '';
                }
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _audioStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Lỗi kết nối: ${snapshot.error.toString()}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Lọc danh sách audio theo từ khóa tìm kiếm
          var docs = snapshot.data!.docs.where((doc) {
            final title = doc['title'].toString().toLowerCase();
            final lowerCaseQuery = searchQuery.toLowerCase();
            return title.contains(lowerCaseQuery);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var docData = docs[index].data() as Map<String, dynamic>;
              return AudioListView(
                title: docData['title'],
                imageUrl: docData['imageUrl'],
                audioId: docs[index].id,
                source: docData['source'], // Gọi callback khi chọn bài hát
              );
            },
          );
        },
      ),
    );
  }
}

class AudioListView extends StatelessWidget {
  final String audioId;
  final String title;
  final String imageUrl;
  final String source;

  const AudioListView({
    super.key,
    required this.audioId,
    required this.title,
    required this.imageUrl,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayAudioPage(audioId: audioId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(15.0, 8.0, 8.0, 8.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipOval(
              child: SizedBox(
                height: 80.0,
                width: 80.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset('assets/logo.png', fit: BoxFit.cover);
                  },
                ),
              ),
            ),
            const SizedBox(width: 15.0),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

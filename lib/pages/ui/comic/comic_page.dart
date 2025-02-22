import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'read_comic_page.dart';

class ComicPage extends StatefulWidget {
  const ComicPage({super.key});

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> {
  String searchQuery = '';
  // Biến hiển thị ô tìm kiếm
  bool isSearching = false;
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    // Lấy stream dữ liệu từ Firestore
    final fetchStream =
        FirebaseFirestore.instance.collection('comics').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: !isSearching
            // Tiêu đề khi không tìm kiếm
            ? const Text(
                'Truyện tranh',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
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
                  // Reset lại tìm kiếm
                  searchQuery = '';
                }
                // Đổi trạng thái
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: fetchStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Lỗi kết nối: ${snapshot.error.toString()}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Lọc danh sách comics dựa trên truy vấn tìm kiếm
          var docs = snapshot.data!.docs.where((doc) {
            final docData = doc.data();
            if (!docData.containsKey('title')) {
              return false; // Kiểm tra trường title
            }
            final title = docData['title'].toString().toLowerCase();
            return title.contains(searchQuery.toLowerCase());
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('Không tìm thấy truyện tranh.'));
          }

          // Hiển thị dạng lưới với 2 cột
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              // 2 cột trên 1 hàng
              crossAxisCount: 2,
              // Khoảng cách ngang giữa các item
              crossAxisSpacing: 24.0,
              // Khoảng cách dọc giữa các item
              mainAxisSpacing: 24.0,
              // Tỉ lệ chiều rộng và chiều cao
              childAspectRatio: 2 / 3,
            ),
            itemBuilder: (context, index) {
              var docData = docs[index].data();
              return ComicGridItem(
                title: docData['title'],
                imageUrl: docData['imageUrl'],
                comicId: docs[index].id,
              );
            },
          );
        },
      ),
    );
  }
}

class ComicGridItem extends StatelessWidget {
  final String comicId;
  final String title;
  final String imageUrl;

  const ComicGridItem({
    super.key,
    required this.comicId,
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Điều hướng sang trang đọc truyện và truyền source
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadComicPage(
              comicId: comicId,
              title: title,
              imageUrl: imageUrl,
            ), // theo id của comic
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 3.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hiển thị ảnh của comic
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Ảnh thay thế
                  return Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            // Tiêu đề comic
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow:
                        TextOverflow.ellipsis, // Tiêu đề sẽ bị cắt nếu quá dài
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:appbook/pages/ui/comic/read_comic_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ListComicPage extends StatefulWidget {
  const ListComicPage({super.key});

  @override
  State<ListComicPage> createState() => _ListComicPageState();
}

class _ListComicPageState extends State<ListComicPage> {
  //Danh sách comic yêu thích
  List<String> comicFavorites = [];

  // Hàm lấy danh sách comic yêu thích từ Firestore
Future<void> getFavorites() async {
  try {
    // Lấy ra userId của người dùng hiện tại
    String? userId = FirebaseAuth.instance.currentUser ?.uid;
    if (userId == null) {
      print("User  is not logged in.");
      return; // Hoặc xử lý tình huống khi người dùng chưa đăng nhập
    }

    // Truy vấn tài liệu người dùng dựa trên userId
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    // Kiểm tra xem tài liệu có tồn tại không
    if (!userDoc.exists) {
      print("User  document does not exist.");
      return;
    }

    print('User  Document: $userDoc');

    // Lấy danh sách yêu thích cho comic
    Map<String, dynamic> favorites = Map<String, dynamic>.from(userDoc['favorites'] ?? {});

    // In danh sách favorites ra console
    print('Favorites: $favorites');

    comicFavorites = List<String>.from(favorites['comic'] ?? []);
    print('Danh sách comic: $comicFavorites');

    setState(() {});
  } catch (e) {
    print('Error fetching favorites: $e');
  }
}

  // Hàm xóa comic yêu thích khỏi Firestore
Future<void> removeFavorite(String comicId) async {
  try {
    // Lấy ra userId của người dùng hiện tại
    String? userId = FirebaseAuth.instance.currentUser ?.uid;
    if (userId == null) {
      print("User  is not logged in.");
      return;
    }

    // Truy vấn tài liệu người dùng dựa trên userId
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    // Kiểm tra xem tài liệu có tồn tại không
    if (!userDoc.exists) {
      print("User  document does not exist.");
      return;
    }

    // Cập nhật danh sách comic yêu thích
    List<String> updatedFavorites =
        List<String>.from(userDoc['favorites']['comic'] ?? []);
    updatedFavorites.remove(comicId);

    // Cập nhật lại Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'favorites.comic': updatedFavorites,
    });

    // Xóa thành công thì cập nhật lại giao diện
    setState(() {
      comicFavorites.remove(comicId);
    });
  } catch (e) {
    print("Error removing favorite: $e");
  }
}

  @override
  void initState() {
    super.initState();
    getFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: comicFavorites.isNotEmpty
              ? ListView.builder(
                  itemCount: comicFavorites.length,
                  itemBuilder: (context, index) {
                    String comicId = comicFavorites[index];
                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('comics')
                          .doc(comicId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        var comicData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        String title = comicData['title'];
                        String imageUrl = comicData['imageUrl'];

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReadComicPage(
                                      comicId: comicId,
                                      title: title,
                                      imageUrl: imageUrl),
                                ));
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 15, top: 10, bottom: 10, right: 10
                                  ),
                                  child: SizedBox(
                                    width:  80,
                                    height: 100,
                                    child: Image.network(
                                      imageUrl,
                                    ),
                                  )
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start, // Căn chỉnh về bên trái
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        softWrap: true, // Tự động xuống dòng nếu quá dài
                                      ),
                                      const SizedBox(height: 10.0),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Giãn cách đều
                                        children: [
                                          Text(
                                            'Số trang: ${comicData['pageCount'].toString()}',
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              removeFavorite(comicId);
                                            },
                                            icon: const FaIcon(FontAwesomeIcons.trashCan),
                                            iconSize: 14.0,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              : const Center(
                  child: Text('Danh sách bị trống!'),
                ),
        ),
      ],
    );
  }
}

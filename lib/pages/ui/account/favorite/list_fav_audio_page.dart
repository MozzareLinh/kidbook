import 'package:appbook/pages/ui/audio/play_audio_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ListAudioPage extends StatefulWidget {
  const ListAudioPage({super.key});

  @override
  State<ListAudioPage> createState() => _ListAudioPageState();
}

class _ListAudioPageState extends State<ListAudioPage> {
  //Danh sách audio yêu thích
  List<String> audioFavorites = [];

  // Hàm lấy danh sách audio yêu thích
  Future<void> getFavorites() async {
    try {
      // Lấy ra userId của người dùng hiện tại
      String? userId = FirebaseAuth.instance.currentUser?.uid;
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

      // Lấy danh sách yêu thích cho audio
      Map<String, dynamic> favorites =
          Map<String, dynamic>.from(userDoc['favorites'] ?? {});

      // Lấy danh sách audio yêu thích
      audioFavorites = List<String>.from(favorites['audio'] ?? []);
      print('Danh sách audio: $audioFavorites');

      setState(() {});
    } catch (e) {
      print("Error fetching favorites: $e");
    }
  }

  // Hàm xóa audio yêu thích ra khỏi danh sách
  Future<void> removeFavorite(String audioId) async {
    try {
      // Lấy ra userId của người dùng hiện tại
      String? userId = FirebaseAuth.instance.currentUser?.uid;
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

      // Cập nhật danh sách audio yêu thích
      List<String> updatedFavorites =
          List<String>.from(userDoc['favorites']['audio'] ?? []);
      updatedFavorites.remove(audioId);

      // Cập nhật lại Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'favorites.audio': updatedFavorites,
      });

      // Xóa thành công thì cập nhật lại giao diện
      setState(() {
        audioFavorites.remove(audioId);
      });
    } catch (e) {
      print("Error removing favorite: $e");
    }
  }

  //Hàm định dạng thời gian về dạng 00:00
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
          // Đảm bảo ListView có chiều cao bị giới hạn
          child: audioFavorites.isEmpty
              ? const Center(
                  child: Text('Danh sách bị trống!'),
                )
              : ListView.builder(
                  itemCount: audioFavorites.length,
                  itemBuilder: (context, index) {
                    String audioId = audioFavorites[index];
                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('audios')
                          .doc(audioId)
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
                        var audioData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        String title = audioData['title'];
                        String imageUrl = audioData['imageUrl'];

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlayAudioPage(audioId: audioId),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 10, 10, 15),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(70.0),
                                    child: Image.network(
                                      imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                // Loại bỏ Expanded vì không cần thiết
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        // Căn trái theo Row
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          // Căn giữa theo chiều dọc
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                // Tự động xuống dòng
                                                softWrap: true,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDuration(
                                                    Duration(
                                                        seconds: audioData[
                                                            'duration']),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  onPressed: () {
                                                    removeFavorite(audioId);
                                                  },
                                                  icon: const FaIcon(
                                                    FontAwesomeIcons.trashCan,
                                                    size: 14.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
                ),
        ),
      ],
    );
  }
}

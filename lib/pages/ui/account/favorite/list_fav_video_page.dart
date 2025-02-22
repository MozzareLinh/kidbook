import 'package:appbook/pages/ui/video/gol/play_gol_page.dart';
import 'package:appbook/pages/ui/video/story/play_story_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ListVideoPage extends StatefulWidget {
  const ListVideoPage({super.key});

  @override
  State<ListVideoPage> createState() => _ListVideoPageState();
}

class _ListVideoPageState extends State<ListVideoPage> {
  //Danh sách video yêu thích
  List<Map<String, dynamic>> favoriteVideos = [];

  // Hàm lấy dữ liệu video yêu thích từ Firestore
  Future<void> fetchFavoriteVideos() async {
    try {
      favoriteVideos = await getFavoriteVideos();
      print('Favorites video là $favoriteVideos');
      setState(() {});
    } catch (e) {
      print("Error fetching videos: $e");
    }
  }

  // Hàm lấy danh sách video yêu thích từ các trường 'gol' và 'story'
  Future<List<Map<String, dynamic>>> getFavoriteVideos() async {
    List<Map<String, dynamic>> favoriteVideos = [];

    try {
      // Lấy ra userId của người dùng hiện tại
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("User  is not logged in.");
        return favoriteVideos;
      }

      // Truy vấn tài liệu của người dùng dựa trên userId
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Kiểm tra xem tài liệu có tồn tại không
      if (!userDoc.exists) {
        print("User  document not found.");
        return favoriteVideos;
      }

      // Lấy danh sách yêu thích cho video
      Map<String, dynamic> favorites = userDoc['favorites'];

      // Lấy danh sách video từ các trường 'gol' và 'story'
      List<String> golVideos = List<String>.from(favorites['gol'] ?? []);
      List<String> storyVideos = List<String>.from(favorites['story'] ?? []);

      // Gộp cả hai danh sách lại thành một
      List<String> allVideos = [...golVideos, ...storyVideos];
      print('Video yêu thích: $allVideos');

      // Lặp qua từng videoId trong danh sách đã gộp
      for (String videoId in allVideos) {
        // Truy vấn dữ liệu từ các collection "gols" và "stories"
        Map<String, dynamic>? videoData = await getVideoData(videoId);
        if (videoData != null) {
          favoriteVideos.add(videoData);
        }
      }

      return favoriteVideos;
    } catch (e) {
      print("Error fetching favorite videos: $e");
      return favoriteVideos;
    }
  }

  // Hàm lấy thông tin video từ hai collection "gols" và "stories"
  Future<Map<String, dynamic>?> getVideoData(String videoId) async {
    try {
      // Tìm video trong collection "gols"
      DocumentSnapshot golDoc = await FirebaseFirestore.instance
          .collection('gols')
          .doc(videoId)
          .get();

      if (golDoc.exists) {
        Map<String, dynamic> videoData = golDoc.data() as Map<String, dynamic>;
        videoData['id'] = golDoc.id; // Lưu trữ id của video
        videoData['videoSource'] = 'gol'; // Thêm thông tin nguồn video
        print('Id là ${golDoc.id}');
        return videoData;
      }

      // Nếu không tìm thấy trong "gols", tìm tiếp trong "stories"
      DocumentSnapshot storyDoc = await FirebaseFirestore.instance
          .collection('stories')
          .doc(videoId)
          .get();

      if (storyDoc.exists) {
        Map<String, dynamic> videoData =
            storyDoc.data() as Map<String, dynamic>;
        videoData['id'] = storyDoc.id; // Lưu trữ id của video
        videoData['videoSource'] = 'story'; // Thêm thông tin nguồn video
        return videoData;
      }

      // Nếu không tìm thấy video
      return null;
    } catch (e) {
      print("Error fetching video data: $e");
      return null;
    }
  }

  // Hàm xóa yêu thích ra khỏi danh sách
  Future<void> removeFavorites(String videoId, String videoSource) async {
    try {
      // Lấy ra userId của người dùng hiện tại
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("User  is not logged in.");
        return;
      }

      // Truy vấn tài liệu của người dùng dựa trên userId
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Kiểm tra xem tài liệu có tồn tại không
      if (!userDoc.exists) {
        print("User  document not found.");
        return;
      }

      Map<String, dynamic> favorites = userDoc['favorites'];

      // Xóa video khỏi danh sách 'gol' hoặc 'story' tùy thuộc vào videoSource
      if (videoSource == 'gol') {
        List<String> golVideos = List<String>.from(favorites['gol'] ?? []);
        golVideos.remove(videoId);
        favorites['gol'] = golVideos;
      } else if (videoSource == 'story') {
        List<String> storyVideos = List<String>.from(favorites['story'] ?? []);
        storyVideos.remove(videoId);
        favorites['story'] = storyVideos;
      }

      // Cập nhật tài liệu của người dùng trên Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .update({'favorites': favorites});

      // Cập nhật lại danh sách yêu thích trong giao diện
      setState(() {
        favoriteVideos.removeWhere((video) => video['id'] == videoId);
      });
    } catch (e) {
      print("Error removing favorite video: $e");
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
    fetchFavoriteVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: favoriteVideos.isNotEmpty
              ? ListView.builder(
                  itemCount: favoriteVideos.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> video = favoriteVideos[index];
                    String title = video['title'];
                    String thumbnailUrl = video['thumbnailUrl'];
                    String source = video['source'];
                    String videoSource = video['videoSource'];
                    return InkWell(
                      onTap: () {
                        // Xử lý sự kiện nhấn nút play
                        if (videoSource == 'gol') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayGOLPage(
                                golId: video['id'],
                                source: source,
                                title: title,
                              ),
                            ),
                          );
                        } else if (videoSource == 'story') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayStoryPage(
                                storyId: video['id'],
                                source: source,
                                title: title,
                              ),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              //Hình ảnh thu nhỏ của video
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                    horizontal: 15.0,
                                  ),
                                  width: 150, // Chiếm toàn bộ chiều rộng
                                  height: 90, // Chiều cao tùy chỉnh
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14.0),
                                    image: DecorationImage(
                                      image: NetworkImage(thumbnailUrl),
                                      //Đảm bảo hình ảnh đầy đủ
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 50.0,
                                height: 50.0,
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
                                    iconSize: 32.0,
                                    onPressed: () {
                                      // Xử lý sự kiện nhấn nút play
                                      if (videoSource == 'gol') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayGOLPage(
                                              golId: video['id'],
                                              source: source,
                                              title: title,
                                            ),
                                          ),
                                        );
                                      } else if (videoSource == 'story') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayStoryPage(
                                              storyId: video['id'],
                                              source: source,
                                              title: title,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        Duration(seconds: video['duration']),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ), // Hiển thị thời gian
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        removeFavorites(
                                            video['id'], video['videoSource']);
                                      },
                                      icon: const FaIcon(
                                        FontAwesomeIcons.trashCan,
                                      ),
                                      iconSize: 14.0,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text("Danh sách bị trống!"),
                ),
        ),
      ],
    );
  }
}

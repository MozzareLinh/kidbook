import 'package:appbook/pages/authentication/password_page.dart';
import 'package:appbook/pages/ui/account/info_account_page.dart';
import 'package:appbook/pages/ui/account/favorite/favorite_list_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../authentication/login_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  //khởi tạo một đối tượng của FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? username; // Không khai báo giá trị mặc định
  String? email;
  String? avatarUrl;
  DateTime? joinDate;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // Lấy ra userId của người dùng hiện tại
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        // Truy vấn từ Firestore bằng userId
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        print('UserId là $userId');

        // Kiểm tra xem tài liệu có tồn tại không
        if (userDoc.exists) {
          setState(() {
            // Nếu không có trường username, gán giá trị là userId
            username = userDoc['username']?.isNotEmpty == true
                ? userDoc['username']
                : _shortenUserId(userId);
            email = userDoc['email'] ?? '';
            joinDate = (userDoc['joinDate'] as Timestamp?)?.toDate();

            print('Tên user: $username');
            print('Email user: $email');
            print('Ngày tham gia: $joinDate');
          });
        } else {
          print('Không tìm thấy người dùng với userId này');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print("User is not logged in.");
    }
  }

  // Hàm rút ngắn userId
  String _shortenUserId(String userId) {
    if (userId.length > 10) {
      // Kiểm tra độ dài
      return '${userId.substring(0, 10)}...${userId.substring(userId.length - 7)}'; // Rút ngắn
    }
    return userId; // Trả về nguyên bản nếu không dài
  }

  //Đăng xuất
  void _signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Bo góc hộp thoại
          ),
          child: SizedBox(
            width: 200, // Chiều rộng tùy chỉnh của dialog
            height: 150, // Chiều cao tùy chỉnh của dialog
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Căn giữa nội dung theo chiều dọc
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Bạn có muốn đăng xuất không?',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      onPressed: () {
                        // Đóng dialog mà không làm gì
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 10.0), // Khoảng cách giữa các nút
                    TextButton(
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      onPressed: () {
                        _signUserOut();
                        Navigator.of(context).pop(); // Đóng dialog
                        // Điều hướng đến trang đăng nhập
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          Container(
            height: 200,
            width: 200,
            padding: const EdgeInsets.all(15.0),
            child: Container(
              padding: const EdgeInsets.only(left: 5, top: 20, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 55,
                    width: 55,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(55.0),
                      child: Image.asset('assets/avatar_a.png'),
                    ),
                  ),
                  const SizedBox(width: 15.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        username ?? 'userId',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        email ?? 'user@gmail.com',
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        joinDate != null
                            ? 'Tham gia từ: ${joinDate!.day}/${joinDate!.month}/${joinDate!.year}'
                            : '',
                        style: const TextStyle(fontSize: 10.0),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InfoAccountPage(),
                        ),
                      );
                    },
                    icon: const FaIcon(FontAwesomeIcons.penToSquare),
                    iconSize: 18,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 40.0),
          Container(
            height: 80,
            width: 100,
            padding: const EdgeInsets.fromLTRB(20.0, 5, 20.0, 5),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PasswordManager(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.watch_later_outlined,
                      size: 20.0,
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      'Thiết lập thời gian đọc',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 80,
            width: 100,
            padding: const EdgeInsets.fromLTRB(20.0, 5, 20.0, 5),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoriteListPage(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.favorite_border_outlined,
                      size: 20.0,
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      'Danh sách yêu thích',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 80,
            width: 100,
            padding: const EdgeInsets.fromLTRB(20.0, 5, 20.0, 5),
            child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: InkWell(
                  onTap: () {
                    _showLogoutConfirmationDialog(context);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.logout,
                        size: 20.0,
                      ),
                      SizedBox(width: 10.0),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )),
          ),
        ],
      ),
    );
  }
}

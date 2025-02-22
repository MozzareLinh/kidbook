import 'package:appbook/pages/ui/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:appbook/pages/authentication/login_page.dart';

class SignupController {
  final TextEditingController yourNameController;
  final TextEditingController userNameController;
  final TextEditingController emailOrNoController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  Map<String, List<String>> favorites;
  final Map<String, int> duration; // duration sẽ lưu trữ hours và minutes
  final List<String> schedule;
  final Timestamp joinDate;
  final BuildContext context;

  SignupController({
    required this.yourNameController,
    required this.userNameController,
    required this.emailOrNoController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.favorites,
    required this.duration,
    required this.schedule,
    required this.joinDate,
    required this.context,
  });

  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm thêm chi tiết người dùng vào Firestore
  Future<void> addUserDetails(
      String userId, String yourName, String userName, String email) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'yourName': yourName,
      'username': userName,
      'email': email,
      'favorites': {
        'comic': [], // Danh sách comic yêu thích rỗng
        'audio': [], // Danh sách sudio yêu thích rỗng
        'story': [], // Danh sách story yêu thích rỗng
        'gol': [], // Danh sách gol yêu thích rỗng
      },
      'lastDate': null,
      'duration': {
        'hours': 0,
        'minutes': 0,
      },
      'remainingTime': {
        'hours': 0,
        'minutes': 0,
        'seconds': 0,
      },
      // Danh sách các ngày được phép đọc sách
      'schedule': [],
      'joinDate': Timestamp.now(),
    });
  }

  //Hàm kiểm tra mật khẩu có khớp ko
  bool passwordConfirmed() {
    return passwordController.text.trim() ==
        confirmPasswordController.text.trim();
  }

  //Signup with email/password
  Future<void> signUserUp() async {
    if (passwordConfirmed()) {
      try {
        //tạo người dùng mới với Firebase Authentication
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailOrNoController.text.trim(),
          password: passwordController.text.trim(),
        );

        //Thêm chi tiết người dùng vào firestore
        await addUserDetails(
          //Lấy UID của ngueoif dùng vừa tạo
          userCredential.user!.uid,
          yourNameController.text.trim(),
          userNameController.text.trim(),
          emailOrNoController.text.trim(),
        );
        //Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng kí thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Chuyển hướng đến trang đăng nhập
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } on FirebaseException catch (e) {
        //Hiển thị lỗi nếu có
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Đăng kí thất bại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      //Hiển thị thông báo nếu mật khẩu không khớp
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu không khớp!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //signup using Google
  Future<void> googleSignUp() async {
    //select user account
    final GoogleSignInAccount? userAccount = await GoogleSignIn().signIn();

    //verify/auth user
    final GoogleSignInAuthentication? googleAuth =
        await userAccount?.authentication;

    //get user credential/personal details
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth!.accessToken,
      idToken: googleAuth.idToken,
    );

    //firebase login with credential of google
    await _auth.signInWithCredential(credential).then((value) async {
      //Lấy thông tin người dùng
      User? user = value.user;

      //Kiểm tra xem người dùng đã tồn tại trong firebase chưa
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();

      if (!userDoc.exists) {
        // Nếu người dùng chưa tồn tại, thêm vào Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'username': '',
          'email': user.email,
          'favorites': {
            'comic': [], // Danh sách comic yêu thích rỗng
            'audio': [], // Danh sách audio yêu thích rỗng
            'story': [], // Danh sách story yêu thích rỗng
            'gol': [], // Danh sách gol yêu thích rỗng
          },
          'lastDate': null,
          'duration': {
            'hours': 0,
            'minutes': 0,
          },
          'remainingTime': {
            'hours': 0,
            'minutes': 0,
            'seconds': 0,
          },
          // Danh sách các ngày được phép đọc sách
          'schedule': [],
          'joinDate': Timestamp.now(),
        });
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đăng nhập thành công ')));
      debugPrint('Đăng kí thành công');

      // Chuyển đến trang home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeTab()),
        (Route<dynamic> route) => false,
      );
    }).onError((error, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập không thành công ')));
      debugPrint('Đăng kí không thành công: $error');
    });
  }
}

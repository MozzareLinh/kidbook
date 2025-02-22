import 'package:appbook/pages/ui/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController {
  final TextEditingController emailOrNoController;
  final TextEditingController passwordController;
  final BuildContext context;

  LoginController({
    required this.emailOrNoController,
    required this.passwordController,
    required this.context,
  });

  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm đăng nhập người dùng
  void logUserIn() async {
    //check any empty
    if (emailOrNoController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      // Hiển thị lỗi nếu có
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng nhập đầy đủ thông tin!'),
        backgroundColor: Colors.red,
      ));
    }
    // Hiển thị vòng tròn loading
    _showLoadingDialog();
    try {
      // Đăng nhập người dùng với Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailOrNoController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Đóng vòng tròn loading
      Navigator.pop(context);

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đăng nhập thành công!'),
        backgroundColor: Colors.green,
      ));

      // Bạn có thể chuyển hướng người dùng tới trang khác sau khi đăng nhập thành công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeTab()),
      );
    } on FirebaseAuthException catch (e) {
      // Đóng vòng tròn loading
      Navigator.pop(context);

      // Hiển thị thông báo lỗi phù hợp
      if (e.code == 'user-not-found') {
        // Hiển thị lỗi nếu có
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email không khớp!'),
          backgroundColor: Colors.red,
        ));
      } else if (e.code == 'wrong-password') {
        // Hiển thị lỗi nếu có
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mật khẩu không khớp!'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // show loading circle
  void _showLoadingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  ////login using Google
  Future<void> googleSignIn() async {
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
      debugPrint('Đăng nhập thành công');

      // Chuyển đến trang home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeTab()),
      );
    }).onError((error, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập không thành công ')));
      debugPrint('Đăng nhập không thành công: $error');
    });
  }
}

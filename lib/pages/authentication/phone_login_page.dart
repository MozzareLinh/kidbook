import 'package:appbook/pages/authentication/otp_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final TextEditingController phoneController = TextEditingController();

  void sendCode() async {
    String phoneNumber = phoneController.text.trim();

    // Kiểm tra số điện thoại hợp lệ trước khi gửi OTP
    if (phoneNumber.isEmpty || phoneNumber.length < 9 || phoneNumber.length > 11) {
      Get.snackbar('Lỗi', 'Vui lòng nhập số điện thoại hợp lệ.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+84$phoneNumber',
        verificationCompleted: (PhoneAuthCredential credential) {
          // Đăng nhập tự động nếu mã OTP hợp lệ
          FirebaseAuth.instance.signInWithCredential(credential).then((user) {
            print("Đăng nhập thành công");
            Get.snackbar('Thành công', 'Đăng nhập tự động hoàn tất.');
          }).catchError((error) {
            print("Đăng nhập thất bại: $error");
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Xác minh thất bại: ${e.code}");
          String errorMessage = e.code == 'invalid-phone-number'
              ? 'Số điện thoại không hợp lệ.'
              : 'Đã xảy ra lỗi khi xác minh số điện thoại.';
          Get.snackbar('Lỗi', errorMessage,
              backgroundColor: Colors.red, colorText: Colors.white);
        },
        codeSent: (String vid, int? token) {
          Get.snackbar('Thành công', 'Mã OTP đã được gửi.',
              backgroundColor: Colors.green, colorText: Colors.white);
          Get.to(() => OTPPage(vid: vid));
        },
        codeAutoRetrievalTimeout: (String vid) {
          print("Hết thời gian tự động xác minh với ID: $vid");
        },
      );
    } on FirebaseAuthException catch (e) {
      print("Lỗi FirebaseAuth: ${e.message}");
      Get.snackbar('Lỗi', e.message ?? 'Đã xảy ra lỗi không xác định.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      print("Lỗi không xác định: $e");
      Get.snackbar('Lỗi', 'Đã xảy ra lỗi không xác định.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập bằng số điện thoại'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 250,
                width: 400,
                child: Image.asset('assets/enterotp.jpg'),
              ),
              const Text(
                'Bạn sẽ nhận được mã OTP từ số điện thoại này!',
                style: TextStyle(fontSize: 20.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Nhập số điện thoại',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: SizedBox(
                  width: 120.0,
                  height: 55.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: sendCode,
                    child: const Text(
                      'Gửi OTP',
                      style: TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

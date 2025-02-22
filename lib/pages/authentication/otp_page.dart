import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class OTPPage extends StatefulWidget {
  final String vid;

  const OTPPage({super.key, required this.vid});

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String otpCode = '';

  void signIn() async {
    if (otpCode.isEmpty || otpCode.length < 6) {
      Get.snackbar('Lỗi', 'Vui lòng nhập mã OTP hợp lệ.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.vid,
        smsCode: otpCode,
      );

      // Đăng nhập bằng OTP
      await _auth.signInWithCredential(credential);

      Get.snackbar('Thành công', 'Đăng nhập thành công.',
          backgroundColor: Colors.green, colorText: Colors.white);

      // Điều hướng tới trang chính
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('Lỗi', 'Mã OTP không hợp lệ hoặc đã hết hạn.',
          backgroundColor: Colors.red, colorText: Colors.white);
      print("Lỗi khi đăng nhập: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác minh OTP'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                width: 300,
                child: Image.asset('assets/otp_verification.png'),
              ),
              const Text(
                'Nhập mã OTP được gửi tới số điện thoại của bạn.',
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              Pinput(
                length: 6,
                defaultPinTheme: defaultPinTheme,
                onCompleted: (pin) {
                  setState(() {
                    otpCode = pin;
                  });
                },
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  onPressed: signIn,
                  child: const Text(
                    'Xác minh',
                    style: TextStyle(color: Colors.white, fontSize: 16.0),
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

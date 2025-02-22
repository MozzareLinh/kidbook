import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../controller/signup_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  //Biến kiểm soát ẩn/hiện mật khẩu
  bool _obscureText = true;
  final yourNameController = TextEditingController();
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    yourNameController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tạo instance của SignupController
    SignupController signupController = SignupController(
      yourNameController: yourNameController,
      userNameController: userNameController,
      emailOrNoController: emailController,
      passwordController: passwordController,
      confirmPasswordController: confirmPasswordController,
      favorites: {}, // Bắt đầu với favorites dạng Map rỗng
      duration: {}, 
      schedule: [],
      joinDate: Timestamp.now(),
      context: context, 
    );
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.only(right: 24.0, left: 24.0, bottom: 16.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              //Logo Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  width: 200.0,
                  height: 200.0,
                  child: Image.asset('assets/logo.png'),
                ),
              ),
              const SizedBox(height: 16.0),

              //First Name Field
              TextFormField(
                controller: yourNameController,
                decoration: InputDecoration(
                  labelText: 'Tên của bạn',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  prefixIcon: const Icon(Icons.text_fields),
                ),
              ),
              const SizedBox(height: 16.0),

              //Email field
              TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  ),
              const SizedBox(height: 16.0),

              //UserName Field
              TextFormField(
                controller: userNameController,
                decoration: InputDecoration(
                  labelText: 'Tên tài khoản',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  prefixIcon: const Icon(Icons.text_fields),
                ),
              ),
              const SizedBox(height: 16.0),

              //Password field
              TextFormField(
                  controller: passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        )),
                  )),
              const SizedBox(height: 16.0),

              //Confirm password
              TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        )),
                  )),
              const SizedBox(height: 16.0),

              //Signup button
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 45.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: () async {
                      signupController.signUserUp();
                    },
                    child: const Text(
                      'Đăng kí',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              //divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.8,
                        color: Colors.grey[400],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'Hoặc đăng kí với',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.8,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              //Others way sign in
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //signin using google
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            backgroundColor: Colors.white,
                            elevation: 5.0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                side: const BorderSide(
                                  color: Colors.grey,
                                  width: 0.8,
                                ))),
                        onPressed: () {
                          signupController.googleSignUp();
                        },
                        child: Image.asset(
                          'assets/gg.png',
                          width: 36, // Size image
                          height: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ));
  }
}

import 'package:appbook/pages/authentication/forgot_pw_page.dart';
import 'package:appbook/pages/authentication/phone_login_page.dart';
import 'package:flutter/material.dart';

import '../../controller/login_controller.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Biến kiểm soát ẩn/hiện mật khẩu
  bool _obscureText = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LoginController loginController = LoginController(
      emailOrNoController: emailController,
      passwordController: passwordController,
      context: context,
    );
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //Logo Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    width: 270.0,
                    height: 270.0,
                    child: Image.asset('assets/logo.png'),
                  ),
                ),
                const SizedBox(height: 16.0),

                //Email field
                TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Nhập email của bạn',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0)),
                      prefixIcon: const Icon(Icons.email),
                    )),
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

                //forgot pw
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPassword(),
                      )),
                  child: const Text('Quên mật khẩu'),
                ),
                const SizedBox(height: 20.0),

                //Login field
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                      onPressed: () async {
                        loginController.logUserIn();
                      },
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30.0),

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
                          'Hoặc đăng nhập với',
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
                const SizedBox(height: 24.0),
                //Others way sign in
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //signin using gg
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
                          onPressed: () async {
                            loginController.googleSignIn();
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
                const SizedBox(height: 16.0),
                //SignUp text
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpPage())),
                  child: const Text('Bạn chưa có tài khoản? Đăng kí ngay'),
                ),
              ],
            ),
          ),
        ));
  }
}

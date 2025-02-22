import 'package:appbook/pages/ui/account/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordManager extends StatefulWidget {
  @override
  _PasswordManagerState createState() => _PasswordManagerState();
}

class _PasswordManagerState extends State<PasswordManager> {
  int _failedAttempts = 0;

  // Hàm hash mật khẩu
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Kiểm tra và xử lý logic mật khẩu
  void _checkAndHandlePassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPassword = prefs.getString('password');

    if (storedPassword == null) {
      // Nếu chưa có mật khẩu, yêu cầu thiết lập
      _showSetPasswordDialog();
    } else {
      // Nếu đã có mật khẩu, yêu cầu nhập mật khẩu
      _showPasswordDialog(storedPassword);
    }
  }

  // Hiển thị dialog thiết lập mật khẩu
  void _showSetPasswordDialog() {
    String newPassword = '';
    String confirmPassword = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thiết lập mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Nhập mật khẩu (4 chữ số)',
                  counterText: '',
                ),
                onChanged: (value) {
                  newPassword = value;
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Xác nhận mật khẩu',
                  counterText: '',
                ),
                onChanged: (value) {
                  confirmPassword = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                if (newPassword.isNotEmpty && newPassword == confirmPassword && newPassword.length == 4) {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('password', _hashPassword(newPassword));
                  Navigator.of(context).pop(); // Đóng dialog
                  _showSuccessDialog('Mật khẩu đã được thiết lập thành công.');
                } else {
                  _showErrorDialog('Mật khẩu không khớp hoặc không hợp lệ.');
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị dialog yêu cầu nhập mật khẩu
  void _showPasswordDialog(String correctPasswordHash) {
    String enteredPassword = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nhập mật khẩu'),
          content: TextField(
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Nhập mật khẩu',
              counterText: '',
            ),
            onChanged: (value) {
              enteredPassword = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (_hashPassword(enteredPassword) == correctPasswordHash) {
                  Navigator.of(context).pop(); // Đóng dialog
                  _navigateToReadingSettings(); // Điều hướng đến trang thiết lập
                } else {
                  setState(() {
                    _failedAttempts++;
                  });
                  _showErrorDialog('Sai mật khẩu. Lần thử: $_failedAttempts');
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị dialog lỗi
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị dialog thành công
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thành công'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Điều hướng đến trang thiết lập thời gian đọc
  void _navigateToReadingSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SchedulePage() ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập thời gian đọc'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _checkAndHandlePassword,
          child: const Text('Nhập mật khẩu'),
        ),
      ),
    );
  }
}

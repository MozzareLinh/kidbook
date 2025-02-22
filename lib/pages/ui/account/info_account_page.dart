import 'package:appbook/pages/ui/account/edit_account_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InfoAccountPage extends StatefulWidget {
  const InfoAccountPage({super.key});

  @override
  State<InfoAccountPage> createState() => _InfoAccountPageState();
}

class _InfoAccountPageState extends State<InfoAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> _fetchAccount() async {
    String? userEmail = _auth.currentUser ?.email;
    if (userEmail != null) {
      try {
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .get();

        if (userQuery.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userQuery.docs.first;
          return userDoc.data() as Map<String, dynamic>?;
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
    return null; // Trả về null nếu không tìm thấy dữ liệu
  }

  void _editUserData() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditAccountPage(),
      ),
    ).then((_) {
      setState(() {}); // Cập nhật lại giao diện khi quay lại
    });
  }

  Widget _infoTextAccount(String label, String data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5.0),
        Text(
          data,
          style: const TextStyle(
            color: Color.fromARGB(255, 116, 114, 114),
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _editUserData,
            icon: const Icon(Icons.edit),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchAccount(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Không có dữ liệu'));
            } else {
              final userData = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15.0),
                    Center(
                      child: SizedBox(
                        height: 100,
                        width: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(55.0),
                          child: Image.asset('assets/avatar_a.png'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    _infoTextAccount('Tên của bạn', userData['yourName'] ?? "Không có"),
                    _infoTextAccount('Nickname', userData['username'] ?? "Không có"),
                    _infoTextAccount('Giới tính', userData['gender'] ?? "Không có"),
                    _infoTextAccount('Email', userData['email'] ?? "Không có"),
                    _infoTextAccount('Số điện thoại', userData['phone'] ?? "Không có"),
                    _infoTextAccount('Tỉnh/thành', userData['city'] ?? "Không có"),
                  ],
                ),
              );
            }
          },
        ),
      )
    );
  }
}
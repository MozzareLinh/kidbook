import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  late String userId;
  String yourName = "Không có";
  String userName = "Không có";
  String phoneNumber = "Không có";
  String city = "Không có";

  final TextEditingController yourNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('Id user là: $userId');

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          setState(() {
            yourName = userData['yourName'] ?? "";
            userName = userData['username'] ?? "";
            phoneNumber = userData['phone'] ?? "";
            selectedGender = userData['gender'] ?? null;
            city = userData['city'] ?? "Không có";
          });

          // Cập nhật controller với dữ liệu từ userDoc
          yourNameController.text = yourName;
          userNameController.text = userName;
          emailController.text = FirebaseAuth.instance.currentUser?.email ?? "";
          phoneNumberController.text = phoneNumber;
          cityController.text = city;
        }
      } else {
        print("Không tìm thấy người dùng với id: $userId");
      }
    } catch (e) {
      print("Lỗi truy vấn dữ liệu người dùng: $e");
    }
  }

  Future<void> _updateUserData() async {
    try {
      // Lấy userId hiện tại
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        print("Không tìm thấy userId.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Không thể lưu thông tin. Vui lòng đăng nhập lại.")),
        );
        return;
      }

      // Cập nhật dữ liệu lên Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'yourName': yourNameController.text.trim(),
        'username': userNameController.text.trim(),
        'phone': phoneNumberController.text.trim(),
        'gender': selectedGender,
        'city': cityController.text.trim(),
      });

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thông tin thành công!")),
      );

      // Quay lại trang trước
      Navigator.pop(context);
    } catch (e) {
      print("Lỗi khi cập nhật dữ liệu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Lỗi khi lưu thông tin. Vui lòng thử lại!")),
      );
    }
  }

  // Hàm dựng TextField
  Widget _buildTextField(String label, TextEditingController controller) {
    String? hintText = controller.text.isEmpty ? 'Vui lòng nhập $label' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        const SizedBox(height: 30.0),
      ],
    );
  }

  // Hàm dựng DropdownButtonFormField cho trường giới tính
  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10.0),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Chọn giới tính',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          value: selectedGender,
          onChanged: (value) {
            setState(() {
              selectedGender = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Vui lòng chọn giới tính';
            }
            return null; // Nếu không có lỗi, trả về null
          },
          items: const [
            DropdownMenuItem(
              value: 'Nam',
              child: Text('Nam'),
            ),
            DropdownMenuItem(
              value: 'Nữ',
              child: Text('Nữ'),
            ),
            DropdownMenuItem(
              value: 'Khác',
              child: Text('Khác'),
            ),
          ],
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
          TextButton(
            onPressed: _updateUserData,
            child: const Text('Lưu',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                )),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 40.0),
              _buildTextField('Họ và tên', yourNameController),
              _buildTextField('Tên đăng nhập', userNameController),
              _buildGenderField(),
              const SizedBox(height: 30.0),
              _buildTextField('Email', emailController),
              _buildTextField('Số điện thoại', phoneNumberController),
              _buildTextField('Tỉnh/thành', cityController),
            ],
          ),
        ),
      ),
    );
  }
}

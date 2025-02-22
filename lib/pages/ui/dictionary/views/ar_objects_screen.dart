import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../app_colors.dart';

class ARObjectsScreen extends StatefulWidget {
  const ARObjectsScreen({super.key, required this.object, required this.isLocal});
  final String object;
  final bool isLocal;

  @override
  State<ARObjectsScreen> createState() => _ARObjectsScreenState();
}

class _ARObjectsScreenState extends State<ARObjectsScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  ARNode? localObjectNode;
  ARNode? webObjectNode;
  bool isAdd = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: ARView(onARViewCreated: onARViewCreated), //Khởi tạo phiên AR
      floatingActionButton: FloatingActionButton(
        onPressed: widget.isLocal
            ? onLocalObjectButtonPressed
            : onWebObjectAtButtonPressed,
        child: Icon(isAdd ? Icons.remove : Icons.add),
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager.onInitialize(
      showFeaturePoints: false, //k hiển thị điểm đặc trưng
      showPlanes: true, //Hiển thị mặt phẳng phát hiện đc
      customPlaneTexturePath: "assets/triangle.png", //Định nghĩa texture cho mặt phẳng phát hiện.
      showWorldOrigin: true, //Hiển thị gốc tọa độ của thế giới AR.
      handleTaps: false,
    );
    this.arObjectManager.onInitialize();
  }

  // Đối tượng ở local
  Future onLocalObjectButtonPressed() async {
    if (localObjectNode != null) {
      // Xóa đối tượng khỏi không gian AR
      await arObjectManager.removeNode(localObjectNode!);
      localObjectNode = null;
      print("Đối tượng đã được xóa khỏi không gian AR.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đối tượng đã được xóa thành công!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Thêm đối tượng mới vào không gian AR
      var newNode = ARNode(
        type: NodeType.localGLTF2, // Loại đối tượng
        uri: widget.object,       // Đường dẫn tới file GLTF
        scale: Vector3(0.2, 0.2, 0.2), // Tỷ lệ
        position: Vector3(0.0, 0.0, 0.0), // Vị trí
        rotation: Vector4(1.0, 0.0, 0.0, 0.0), // Xoay
      );

      bool? didAddLocalNode = await arObjectManager.addNode(newNode);
      if (didAddLocalNode == true) {
        localObjectNode = newNode;
        print("Đối tượng đã được thêm thành công vào không gian AR!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đối tượng đã hiển thị thành công!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print("Không thể thêm đối tượng local vào không gian AR.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Không thể thêm đối tượng local vào không gian AR.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

// Đối tượng ở web
  Future onWebObjectAtButtonPressed() async {
    setState(() {
      isAdd = !isAdd;
    });

    if (webObjectNode != null) {
      // Xóa đối tượng khỏi không gian AR
      await arObjectManager.removeNode(webObjectNode!);
      webObjectNode = null;
      print("Đối tượng đã được xóa khỏi không gian AR.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đối tượng đã được xóa thành công!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Thêm đối tượng mới vào không gian AR
      var newNode = ARNode(
        type: NodeType.webGLB, // Loại đối tượng
        uri: widget.object,   // URL đối tượng từ web
        scale: Vector3(0.2, 0.2, 0.2), // Tỷ lệ
      );

      bool? didAddWebNode = await arObjectManager.addNode(newNode);
      if (didAddWebNode == true) {
        webObjectNode = newNode;
        print("Đối tượng đã được thêm thành công vào không gian AR!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đối tượng web đã hiển thị thành công!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print("Không thể thêm đối tượng web vào không gian AR.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Không thể thêm đối tượng web vào không gian AR.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }
}
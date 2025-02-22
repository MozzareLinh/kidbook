import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReadComicPage extends StatefulWidget {
  final String comicId;
  final String title;
  final String imageUrl;

  const ReadComicPage(
      {super.key,
      required this.comicId,
      required this.title,
      required this.imageUrl});

  @override
  State<ReadComicPage> createState() => _ReadComicPageState();
}

class _ReadComicPageState extends State<ReadComicPage> {
  //Thời gian đọc còn lại
  int _remainingTime = 0;

  //Thời gian đọc mặc định
  int _duration = 0;

  //Lịch đọc
  List<String> _schedule = [];

  //Lần truy cập cuối cùng
  DateTime? _lastDate;

  //Timer để cập nhật đồng hồ
  Timer? _timer;

  //tạo biến để theo dõi chế độ đọc
  bool isVerticalMode = true;

  //Biến để lưu title truyện
  String comicTitle = '';

  //khởi tạo một đối tượng của FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // //biến yêu thích
  bool isFavorite = false;

  // Biến để kiểm tra xem dialog đã mở hay chưa
  bool _isDialogOpen = false;

  // Sử dụng ValueNotifier để theo dõi thời gian còn lại
  ValueNotifier<int> remainingTimeNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Hàm khởi tạo dữ liệu
  Future<void> _initializeData() async {
    await _fetchLastDate(); // Kiểm tra lần truy cập cuối cùng

    // Kiểm tra nếu là ngày mới
    if (_isNewDay()) {
      await _resetForNewDay(); // Reset lại remainingTime và kiểm tra lịch từ đầu
    } else {
      // Nếu là ngày cũ, trước tiên cập nhật lịch
      await _fetchSchedule(); // Cập nhật lịch từ Firestore

      // Kiểm tra xem hôm nay có trong lịch không
      if (await _isTodayAllowed()) {
        await Future.wait([
          _fetchComicTitle(), // Lấy tiêu đề truyện
          _checkIfFavorite(), // Kiểm tra yêu thích
          _fetchRemainingTime(), // Tiếp tục từ thời điểm dừng lại
          _fetchDuration(), // Lấy thời gian đọc mặc định
        ]);
        _startTimer(); // Tiếp tục đếm giờ
      } else {
        _showNotAllowedDialog(); // Hiển thị thông báo không được phép đọc
      }
    }
  }

// Hàm kiểm tra nếu là ngày mới
  bool _isNewDay() {
    DateTime now = DateTime.now();
    // Nếu lastDate chưa có (null), nghĩa là ngày mới
    if (_lastDate == null) {
      print('Ngày mới, reset lại thời gian!');
      return true;
    }

    // So sánh ngày hiện tại với lastDate
    bool isNewDay = now.year != _lastDate!.year ||
        now.month != _lastDate!.month ||
        now.day != _lastDate!.day;

    if (isNewDay) {
      print("Đây là ngày mới! Reset lại remainingTime.");
    } else {
      print("Đây là ngày cũ. Tiếp tục từ thời gian dừng lại.");
    }

    return isNewDay;
  }

// Reset lại remainingTime và kiểm tra lịch từ đầu nếu là ngày mới
  Future<void> _resetForNewDay() async {
    await _fetchSchedule(); // Lấy lịch từ Firestore

    if (await _isTodayAllowed()) {
      await Future.wait([
        _fetchComicTitle(), // Lấy tiêu đề truyện
        _checkIfFavorite(), // Kiểm tra yêu thích
        _resetRemainingTime(), // Reset lại thời gian đọc
        _fetchDuration(), // Lấy thời gian đọc mặc định
      ]);
      _startTimer(); // Bắt đầu đếm giờ
    } else {
      _showNotAllowedDialog(); // Không được phép đọc truyện hôm nay
    }

    // Cập nhật lastDate trong Firestore
    await _updateLastDate();
  }

// Hàm cập nhật lastDate trong Firestore
  Future<void> _updateLastDate() async {
    String? userId = _auth.currentUser?.uid;
    DateTime now = DateTime.now();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'lastDate': now});
      _lastDate = now; // Cập nhật lastDate cục bộ
    } catch (e) {
      print('Lỗi cập nhật lastDate: $e');
    }
  }

// Lấy lastDate từ Firestore
  Future<void> _fetchLastDate() async {
    String? userId = _auth.currentUser?.uid;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Lấy giá trị lastDate nếu có
        Timestamp? lastDateTimestamp = userDoc['lastDate'] as Timestamp?;
        _lastDate = lastDateTimestamp?.toDate();
        print('Lần truy cập cuối cùng là: $_lastDate');
      } else {
        print('Không tìm thấy người dùng với userId: $userId');
      }
    } catch (e) {
      print('Lỗi truy vấn lastDate: $e');
    }
  }

// Hàm reset lại remainingTime (cho ngày mới)
  Future<void> _resetRemainingTime() async {
    String? userId = _auth.currentUser?.uid;
    try {
      // Lấy duration từ Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Đảm bảo thời gian là Map<String, dynamic>
        var durationData = userDoc['duration'] as Map<String, dynamic>? ??
            {'hours': 0, 'minutes': 0};

        // Chuyển đổi duration thành giây
        _duration = _mapToSeconds(durationData);

        if (_duration > 0) {
          _remainingTime =
              _duration; // Gán remainingTime bằng duration từ Firestore
          print('Đã reset remainingTime thành: $_remainingTime giây');

          // Lưu giá trị mới vào Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'remainingTime': {
              'hours': _duration ~/ 3600,
              'minutes': (_duration % 3600) ~/ 60,
              'seconds': _duration % 60,
            }
          });
        } else {
          print(
              'Warning: Duration từ Firestore là 0 giây, không thể reset remainingTime!');
        }
      } else {
        print('Không tìm thấy người dùng với userId: $userId');
      }
    } catch (e) {
      print('Lỗi reset remainingTime: $e');
    }
  }

// Kiểm tra xem hôm nay có trong lịch không
  Future<bool> _isTodayAllowed() async {
    DateTime now = DateTime.now();
    int weekday = now.weekday; // 1 = Thứ 2, 7 = Chủ nhật

    // Map ngày trong tuần
    Map<int, String> weekdayMap = {
      1: "2", // Thứ 2
      2: "3", // Thứ 3
      3: "4", // Thứ 4
      4: "5", // Thứ 5
      5: "6", // Thứ 6
      6: "7", // Thứ 7
      7: "CN", // Chủ nhật
    };

    String today = weekdayMap[weekday] ?? "";
    print('Hôm nay là thứ $today');

    // Kiểm tra lịch đọc hôm nay
    if (_schedule.contains(today)) {
      return true; // Nếu hôm nay có trong lịch
    } else {
      print("Hôm nay không nằm trong lịch đọc.");
      return false; // Ngày hôm nay không nằm trong lịch
    }
  }

  //Hàm lấy lịch từ firestore
  Future<void> _fetchSchedule() async {
    String? userId = _auth.currentUser?.uid;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        _schedule = List<String>.from(userDoc['schedule'] ?? []);
        print('Lịch đọc trong tuần là: $_schedule');
      } else {
        print('Không tìm thấy người dùng với userId: $userId');
      }
    } catch (e) {
      print('Lỗi try vấn dữ liệu người dùng: $e');
    }
  }

  //Hiển thị thông báo cho schedule
  void _showNotAllowedDialog() {
    showDialog(
        context: context,
        barrierDismissible: false, // Không cho phép đóng khi nhấn ra ngoài
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Không được phép đọc truyện!'),
            content: const Text(
                'Hôm nay không được phép đọc sách! Bạn vui lòng quay lại sau.'),
            actions: [
              TextButton(
                onPressed: () {
                  //Đóng dialog
                  Navigator.of(context).pop();
                  //Quay về trang trước
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
  }

  // Hàm chuyển đổi từ map thành giây
  int _mapToSeconds(Map<String, dynamic> timeMap) {
    return (timeMap['hours'] ?? 0) * 3600 +
        (timeMap['minutes'] ?? 0) * 60 +
        (timeMap['seconds'] ?? 0);
  }

  // Lấy thời gian đọc mặc định từ Firestore
  Future<void> _fetchDuration() async {
    String? userId = _auth.currentUser?.uid;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Đảm bảo thời gian là Map<String, dynamic>
        var durationData = userDoc['duration'] as Map<String, dynamic>? ??
            {
              'hours': 0,
              'minutes': 0,
            };
        _duration = _mapToSeconds(durationData);
        _remainingTime = _duration; // Bắt đầu từ thời gian mặc định
        await _fetchRemainingTime(); // Gọi hàm lấy thời gian còn lại
        // _startTimer();
      } else {
        print('Không tìm thấy người dùng với userId: $userId');
      }
    } catch (e) {
      print("Lỗi truy vấn dữ liệu người dùng: $e");
    }
  }

//Lấy thời gian còn lại từ Firestore
  Future<void> _fetchRemainingTime() async {
    String? userId = _auth.currentUser?.uid;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Đảm bảo thời gian là Map<String, dynamic>
        var remainingTimeData =
            userDoc['remainingTime'] as Map<String, dynamic>? ??
                {
                  'hours': 0,
                  'minutes': 0,
                  'seconds': 0,
                };
        _remainingTime = _mapToSeconds(remainingTimeData);
        _startTimer();
      } else {
        print('Không tìm thấy người dùng với userId: $userId');
      }
    } catch (e) {
      print("Lỗi truy vấn dữ liệu người dùng: $e");
    }
  }

  // Bộ đếm thời gian
  void _startTimer() {
    DateTime startTime = DateTime.now();
    int initialRemainingTime = _remainingTime;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      int elapsedSeconds = DateTime.now().difference(startTime).inSeconds;

      _remainingTime = initialRemainingTime - elapsedSeconds;

      if (_remainingTime > 0) {
        remainingTimeNotifier.value =
            _remainingTime; // Cập nhật thời gian còn lại
      } else {
        _remainingTime = 0; // Đặt thời gian còn lại về 0
        remainingTimeNotifier.value = _remainingTime; // Cập nhật giao diện

        // Dừng Timer
        _timer?.cancel();

        // Chỉ hiển thị dialog nếu widget còn tồn tại
        if (mounted && !_isDialogOpen) {
          _isDialogOpen = true; // Đánh dấu dialog đã mở
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Kiểm tra lại nếu widget còn mounted
              _showTimeUpDialog(); // Gọi hàm mà không sử dụng giá trị trả về
            }
          });
        }
      }
    });
  }

  // Hiển thị thông báo khi hết giờ
  Future<void> _showTimeUpDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép đóng khi nhấn ra ngoài
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hết giờ!"),
          content: const Text(
              'Thời gian đọc của bạn đã hết! Vui lòng quay lại sau.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    ).then((_) {
      // Quay lại trang trước sau khi dialog đã đóng
      Navigator.of(context).pop(); // Đảm bảo rằng bạn quay về trang trước
    });
  }

  //Chuyển đổi thời gian giây thành định dạng 00h:00p:00s
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  // Lưu thời gian còn lại vào Firestore khi thoát
  Future<void> _saveRemainingTime() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      int hours = _remainingTime ~/ 3600;
      int minutes = (_remainingTime % 3600) ~/ 60;
      int seconds = _remainingTime % 60;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'remainingTime': {
          'hours': hours,
          'minutes': minutes,
          'seconds': seconds,
        },
      });
    } catch (e) {
      print('Lỗi khi lưu thời gian còn lại: $e');
    }
  }

  //Kiểm tra nếu comic đã có trong danh sách yêu thích
  Future<void> _checkIfFavorite() async {
    try {
      //Lấy ra userId của người dùng hiện tại gán = userId
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        //lấy ra thông tin của người dùng dựa trên userId
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          //Lấy ra các phần tử trong danh sách favorites trong user hiện tại và đưa vào danh sách favorites
          Map<String, dynamic> favorites = Map<String, dynamic>.from(userSnapshot['favorites'] ?? {});
          //Đặt lại trạng thái
          setState(() {
            // Kiểm tra xem comicId hiện tại có nằm trong danh sách comic trong favorites không
            isFavorite = favorites['comic'] != null && (favorites['comic'] as List<dynamic>).contains(widget.comicId);
          });
        }
      }
    } catch (e) {
      print('Lỗi khi kiểm tra yêu thích: $e');
    }
  }

  // Hàm thêm hoặc bỏ comic khỏi danh sách yêu thích
  Future<void> _toggleFavorite() async {
    // Lấy ra userId của người dùng hiện tại
    String? userId = _auth.currentUser?.uid;
    print('User  ID người dùng: $userId');
    if (userId == null) return;

    // Lấy ra thông tin của người dùng dựa trên userId
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Kiểm tra dữ liệu lấy
    if (userSnapshot.exists) {
      // print('Dữ liệu người dùng: ${userSnapshot.data()}');
      DocumentReference userRef = userSnapshot.reference;

      try {
        Map<String, dynamic> favorites =
            Map<String, dynamic>.from(userSnapshot['favorites'] ?? {});
        // Lấy danh sách comic hiện tại trong favorites
        List<dynamic> comicFavorites =
            List<dynamic>.from(favorites['comic'] ?? []);

        // Kiểm tra nếu comicId đã có trong danh sách yêu thích hay chưa
        if (comicFavorites.contains(widget.comicId)) {
          // Nếu có, thì xóa khỏi danh sách
          comicFavorites.remove(widget.comicId);
        } else {
          // Nếu chưa, thì thêm vào danh sách
          comicFavorites.add(widget.comicId);
        }

        // Cập nhật lại danh sách comic trong favorites
        favorites['comic'] = comicFavorites;

        // Cập nhật danh sách yêu thích trong Firestore
        await userRef.update({'favorites': favorites});
        setState(() {
          isFavorite = !isFavorite; // Cập nhật trạng thái yêu thích
        });
      } catch (e) {
        print('Lỗi khi cập nhật yêu thích: $e');
      }
    } else {
      print('Không tìm thấy người dùng với userId: $userId');
    }
  }

  //Hàm lấy tiêu đề của truyện từ Firestore
  Future<void> _fetchComicTitle() async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('comics')
          .doc(widget.comicId)
          .get();
      setState(() {
        comicTitle = docSnapshot['title'] ?? 'Title';
      });
    } catch (e) {
      //xử lí lỗi nếu có
      print('Lỗi khi lấy tiêu đề truyện: $e');
    }
  }

  @override
  void dispose() {
    _saveRemainingTime();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước của màn hình để điều chỉnh ảnh
    final screenSize = MediaQuery.of(context).size;

    //lấy dữ liệu từ firebase
    final fetchStream = FirebaseFirestore.instance
        .collection('comics')
        .doc(widget.comicId) //Hiển thị theo id của collection được chọn
        .collection('source') //subcollection con của collection comics
        .orderBy('pageNumber') //sắp xếp theo số trang
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        //Hiển thị tiêu đề truyện nếu có, nếu k có hiển thị đọc truyện
        title: Text(
          comicTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18
          ),
        ),
        actions: [
          //favorite button
          IconButton(
            onPressed: () {
              _toggleFavorite();
            },
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? Colors.red : Colors.white,
          ),
          IconButton(
            onPressed: () {
              setState(() {
                isVerticalMode = !isVerticalMode;
              });
            },
            icon: Icon(
              isVerticalMode ? Icons.view_list : Icons.view_comfy,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thời gian đọc
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ValueListenableBuilder<int>(
              valueListenable: remainingTimeNotifier,
              builder: (context, remainingTime, child) {
                return Text(
                  'Thời gian đọc: ${_formatTime(remainingTime)}',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fetchStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Lỗi kết nối: ${snapshot.hasError.toString()}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    //hiển thị thanh loading
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Không có dữ liệu'),
                  );
                }
                var pages = snapshot.data!.docs;
                return isVerticalMode
                    //Sử dụng ListView để cuộn từng trang truyện theo chiều dọc
                    ? ListView.builder(
                        itemCount: pages.length,
                        itemBuilder: (context, index) {
                          var pageData =
                              pages[index].data() as Map<String, dynamic>;
                          String pageUrl = pageData['pageUrl'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Image.network(
                              pageUrl,
                              fit: BoxFit.contain, //Đảm bảo vừa khít màn hình
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  // Ảnh thay thế khi bị lỗi connection
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          );
                        },
                      )
                    //Hiển thị các trang truyện dưới dạng ListView với scollDirection Horizontal để người dùng có thể cuộn ngang
                    : ListView.builder(
                        // Cuộn theo chiều ngang
                        scrollDirection: Axis.horizontal,
                        itemCount: pages.length,
                        itemBuilder: (context, index) {
                          var pageData =
                              pages[index].data() as Map<String, dynamic>;
                          String pageUrl = pageData['pageUrl'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              pageUrl,
                              //ảnh hiển thị vừa khít màn hình
                              fit: BoxFit.contain,
                              //chiều dài chiều rộng của page = chiều dài chiều rộng của màn hình
                              width: screenSize.width,
                              height: screenSize.height,
                            ),
                          );
                        },
                      );
              },
            ),
          )
        ],
      ),
    );
  }
}

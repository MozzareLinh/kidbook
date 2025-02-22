import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

import 'gol_page.dart';

class PlayGOLPage extends StatefulWidget {
  final String golId;
  final String source;
  final String title;

  const PlayGOLPage({
    super.key,
    required this.golId,
    required this.source,
    required this.title,
  });

  @override
  State<PlayGOLPage> createState() => _PlayGOLPageState();
}

class _PlayGOLPageState extends State<PlayGOLPage> {
  late VideoPlayerController _controller;
  bool _showControls = false;

  // Biến kiểm soát thanh progress bar
  bool _showProgressBar = true;

  // Thêm timer cho nút Controll video
  Timer? _hideControlsTimer;

  // Thêm timer cho thanh progressbar
  Timer? _hideProgressBarTimer;

  // Thêm timer cho nút fullscreen
  Timer? _hideFullScreenButtonTimer;

  // Biến kiểm soát chế độ toàn màn hình
  bool _isFullScreen = false;

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

  // Biến để kiểm tra xem dialog đã mở hay chưa
  bool _isDialogOpen = false;

  //danh sách video
  List<GOL> _videoList = [];

  //biến yêu thích
  bool isFavorite = false;

  //khởi tạo một đối tượng của FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sử dụng ValueNotifier để theo dõi thời gian còn lại
  ValueNotifier<int> remainingTimeNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.source))
      ..initialize().then((_) {
        setState(() {
          // _controller.play();
        });
      });
    _controller.addListener(_videoListener);
    //lấy video ngẫu nhiên khi khởi tạo
    _fetchRandomVideos();
    _checkIfFavorite();
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
          _checkIfFavorite(), // Kiểm tra yêu thích
          _fetchRemainingTime(), // Tiếp tục từ thời điểm dừng lại
          _fetchDuration(), // Lấy thời gian đọc mặc định
        ]);
        // Chỉ phát video nếu người dùng còn thời gian và được phép đọc hôm nay
        if (_remainingTime > 0) {
          _controller.play(); // Phát video nếu hợp lệ
          _startTimer(); // Tiếp tục đếm giờ
        } else {
          _showTimeUpDialog(); // Hiển thị thông báo hết thời gian đọc
        }
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
        _checkIfFavorite(), // Kiểm tra yêu thích
        _resetRemainingTime(), // Reset lại thời gian đọc
        _fetchDuration(), // Lấy thời gian đọc mặc định
      ]);
      // Chỉ phát video nếu người dùng còn thời gian đọc
      if (_remainingTime > 0) {
        _controller.play(); // Phát video nếu hợp lệ
        _startTimer(); // Bắt đầu đếm giờ
      } else {
        _showTimeUpDialog(); // Không được phép đọc do hết thời gian
      }
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

        // Dừng video và Timer
        _controller.pause();
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

  //lấy all video trong collection gols
  void _fetchRandomVideos() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('gols').get();
    final List<GOL> allVideos = snapshot.docs.map((doc) {
      print('DocumnetId: ${doc.id}');
      return GOL(
        golId: doc.id,
        title: doc['title'],
        thumbnailUrl: doc['thumbnailUrl'],
        source: doc['source'] as String,
        duration: Duration(seconds: doc['duration'] as int),
      );
    }).toList();
    //Lấy ngẫu nhiên 15 video
    _videoList = _getRandomVideos(allVideos, 15);
    setState(() {});
  }

  //hàm lấy ngẫu nhiên count video
  List<GOL> _getRandomVideos(List<GOL> videos, int count) {
    final random = Random();
    // Shuffle danh sách video và lấy ra count video đầu tiên
    videos.shuffle(random);
    return videos.take(count).toList();
  }

  void _videoListener() {
    // Không gọi setState ở đây nếu sử dụng ValueListenableBuilder
  }

  @override
  void dispose() {
    //giải phóng tài nguyên
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _hideControlsTimer?.cancel();
    _hideProgressBarTimer?.cancel(); // Hủy timer ẩn thanh progress bar
    _hideFullScreenButtonTimer?.cancel(); // Hủy timer ẩn nút fullscreen
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      _isFullScreen = false; // Đặt lại trạng thái khi thoát
    }
    _saveRemainingTime();
    _timer?.cancel();
    super.dispose();
  }

  //Điều khiển việc phát/dừng video
  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _showControls = true; // Hiển thị lại các nút điều khiển
    _startHideControlsTimer(); // Bắt đầu đếm giờ để ẩn nút
    _startHideProgressBarTimer(); // Bắt đầu đếm giờ để ẩn thanh progress bar
    _startHideFullScreenButtonTimer(); // Bắt đầu đếm giờ để ẩn nút fullscreen
    setState(() {}); // Cập nhật giao diện
  }

  //Ẩn nút play/pause sau 3s
  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  //Ẩn thanh trạng thái sau 3s
  void _startHideProgressBarTimer() {
    _hideProgressBarTimer?.cancel();
    _hideProgressBarTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showProgressBar = false;
      });
    });
  }

  //Ẩn nút fullscreen sau 3s
  void _startHideFullScreenButtonTimer() {
    _hideFullScreenButtonTimer?.cancel();
    _hideFullScreenButtonTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        // Ẩn nút fullscreen sau 3 giây
      });
    });
  }

  //Dùng để bật/tắt các nút điều khiển bằng cách nhấn vào video.
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      // Hiện lại thanh progress bar khi chạm vào video
      _showProgressBar = true;
      if (_showControls) {
        _startHideControlsTimer();
        // Bắt đầu đếm giờ để ẩn nút fullscreen
        _startHideFullScreenButtonTimer();
      }
    });
  }

  //hàm chuyển đổi giữa chế độ toàn màn hình và chế độ bình thường
  void _toggleFullScreen() {
    setState(() {
      // Chuyển đổi trạng thái toàn màn hình
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // Chuyển sang landscape mode ẩn thanh trạng thái
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    } else {
      // Quay về portrait mode
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  //Hàm định dạng thời gian về dạng 00:00
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Kiểm tra nếu gol đã có trong danh sách yêu thích
  Future<void> _checkIfFavorite() async {
    try {
      // Lấy ra userId của người dùng hiện tại
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Lấy ra thông tin của người dùng dựa trên userId
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        // Kiểm tra dữ liệu lấy
        if (userSnapshot.exists) {
          // Lấy ra các phần tử trong danh sách favorites trong user hiện tại
          Map<String, dynamic> favorites =
              Map<String, dynamic>.from(userSnapshot['favorites'] ?? {});

          // Đặt lại trạng thái
          setState(() {
            // Kiểm tra xem golId hiện tại có nằm trong danh sách gol trong favorites không
            isFavorite = favorites['gol'] != null &&
                (favorites['gol'] as List<dynamic>).contains(widget.golId);
          });
        } else {
          print('Không tìm thấy người dùng với userId: $userId');
        }
      }
    } catch (e) {
      print('Lỗi khi kiểm tra yêu thích: $e');
    }
  }

  //Hàm thêm hoặc bỏ gol khỏi ds yêu thích=
  Future<void> _toggleFavorite() async {
    // Lấy ra userId của người dùng hiện tại
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Lấy ra thông tin của người dùng dựa trên userId
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Kiểm tra dữ liệu lấy
    if (userSnapshot.exists) {
      DocumentReference userRef = userSnapshot.reference;

      try {
        // Lấy danh sách favorites (bao gồm comic, audio, story, gol)
        Map<String, dynamic> favorites =
            Map<String, dynamic>.from(userSnapshot['favorites'] ?? {});

        // Lấy danh sách gol hiện tại trong favorites
        List<dynamic> golFavorites = List<dynamic>.from(favorites['gol'] ?? []);

        // Kiểm tra nếu golId đã có trong danh sách yêu thích hay chưa
        if (golFavorites.contains(widget.golId)) {
          // Nếu có, thì xóa khỏi danh sách
          golFavorites.remove(widget.golId);
        } else {
          // Nếu chưa, thì thêm vào danh sách
          golFavorites.add(widget.golId);
        }

        // Cập nhật lại danh sách gol trong favorites
        favorites['gol'] = golFavorites;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context); // Trở về trang trước
                },
              ),
            ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return Column(
            children: [
              // Video player
              SizedBox(
                width: double.infinity,
                height: isLandscape
                    ? MediaQuery.of(context).size.height
                    : 180, // Giữ nguyên chiều cao khi ở chế độ dọc
                child: Center(
                  child: _controller.value.isInitialized
                      ? GestureDetector(
                          onTap: _toggleControls,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio: _controller.value.aspectRatio,
                                child: VideoPlayer(_controller),
                              ),
                              //Hiển thị thanh progressbar
                              if (_showProgressBar)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ValueListenableBuilder<VideoPlayerValue>(
                                        valueListenable: _controller,
                                        builder: (context, value, child) {
                                          return SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                              activeTrackColor:
                                                  Colors.deepPurple,
                                              inactiveTrackColor: Colors.grey,
                                              //nút tròn
                                              thumbShape: const RoundSliderThumbShape( enabledThumbRadius: 8.0),
                                              //Hiệu ứng khi kéo nút tròn
                                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                                              //Màu của nút tròn
                                              thumbColor: Colors.deepPurple,
                                            ),
                                            child: Slider(
                                              min: 0.0,
                                              max: value.duration.inSeconds
                                                  .toDouble(),
                                              value: value.position.inSeconds
                                                  .toDouble(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  _controller.seekTo(Duration(seconds: newValue.toInt()));
                                                });
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      //Hiển thị thời gian hiện tại và tổng thời gian của video
                                      ValueListenableBuilder<VideoPlayerValue>(
                                        valueListenable: _controller,
                                        builder: (context, value, child) {
                                          final position = value.position;
                                          final duration = value.duration;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                              vertical: 4.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDuration(position),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12.0,
                                                  ),
                                                ),
                                                Text(
                                                  _formatDuration(duration),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              if (_showControls)
                                Positioned(
                                  child: GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 0.8),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _controller.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_showControls)
                                Positioned(
                                  right: 10.0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      _toggleFullScreen();
                                      _startHideFullScreenButtonTimer();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
              // Các nút yêu thích và chia sẻ khi không ở chế độ toàn màn hình
              if (!isLandscape) const SizedBox(height: 10),
              if (!isLandscape)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        _toggleFavorite();
                      },
                      icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                      ),
                      color: isFavorite ? Colors.red : Colors.black,

                    ),
                  ],
                ),
              if (!isLandscape)
                // Thời gian đọc
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: ValueListenableBuilder<int>(
                    valueListenable: remainingTimeNotifier,
                    builder: (context, remainingTime, child) {
                      return Text(
                        'Thời gian đọc: ${_formatTime(remainingTime)}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold
                        ),
                      );
                    },
                  ),
                ),
              if (!isLandscape)
                const Text(
                  'More videos',
                  style: TextStyle(fontSize: 14.0),
                ),
              if (!isLandscape) const SizedBox(height: 15.0),
              // Danh sách story
              if (!isLandscape)
                Expanded(
                  child: ListView.builder(
                    itemCount: _videoList.length,
                    itemBuilder: (context, index) {
                      final video = _videoList[index];
                      return GestureDetector(
                        onTap: () {
                          // Chuyển đến video được chọn và thay thế trang hiện tại
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayGOLPage(
                                golId: video.golId,
                                source: video.source,
                                title: video.title,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0), // Tạo khoảng cách giữa các video
                          child: Row(
                            children: [
                              // Hiển thị thumbnail
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    video.thumbnailUrl,
                                    width: 120, // Đặt chiều rộng cho thumbnail
                                    height: 70, // Đặt chiều cao cho thumbnail
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Khoảng cách giữa thumbnail và tiêu đề
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video.title,
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      // Hiển thị thời gian video
                                      _formatDuration(video.duration),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

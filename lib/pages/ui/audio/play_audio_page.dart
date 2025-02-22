import 'dart:async';
import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_player_manager.dart';

class PlayAudioPage extends StatefulWidget {
  final String audioId;

  const PlayAudioPage({
    super.key,
    required this.audioId,
  });

  @override
  State<PlayAudioPage> createState() => _PlayAudioPageState();
}

class _PlayAudioPageState extends State<PlayAudioPage> {
  late String title;
  late String imageUrl;
  late String source;
  late int duration;
  bool isLoading = true;
  late AudioPlayerManager _audioPlayerManager;
  late int _selectedItemIndex;
  late List<DocumentSnapshot> audios; // Danh sách các audio
  bool _isShuffle = false;
  //biến lặp
  late LoopMode _loopMode;
  //biến yêu thích
  bool isFavorite = false;
  //khởi tạo một đối tượng của FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isMiniPlayerVisible = false;

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

  // Sử dụng ValueNotifier để theo dõi thời gian còn lại
  ValueNotifier<int> remainingTimeNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchAudioDetails();
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
        _checkIfFavorite(), // Kiểm tra yêu thích
        _resetRemainingTime(), // Reset lại thời gian đọc
        _fetchDuration(), // Lấy thời gian đọc mặc định
      ]);
      _startTimer(); // Bắt đầu đếm giờ
    } else {
      _showNotAllowedDialog();
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
        // Dừng audio
        _audioPlayerManager.stopAudio();

        // Chỉ hiển thị dialog nếu widget còn tồn tại
        if (mounted && !_isDialogOpen) {
          _isDialogOpen = true; // Đánh dấu dialog đã mở
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Kiểm tra lại nếu widget còn mounted
              _showTimeUpDialog();
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

  //Kiểm tra nếu audio đã có trong danh sách yêu thích
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
          Map<String, dynamic> favorites =
          Map<String, dynamic>.from(userSnapshot['favorites'] ?? {});
          //Đặt lại trạng thái
          setState(() {
            // Kiểm tra xem audioId hiện tại có nằm trong favorites không
            isFavorite = favorites['audio'] != null &&
                (favorites['audio'] as List<dynamic>).contains(widget.audioId);
          });
        }
      }
    } catch (e) {
      print('Lỗi khi kiểm tra yêu thích: $e');
    }
  }

  // Hàm thêm hoặc bỏ audio khỏi danh sách yêu thích
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
        Map<String, dynamic> favorites = Map<String, dynamic>.from(userSnapshot['favorites'] ?? {});
        // Lấy danh sách audio hiện tại trong favorites
        List<dynamic> audioFavorites = List<dynamic>.from(favorites['audio'] ?? []);

        // Kiểm tra nếu audioId đã có trong danh sách yêu thích hay chưa
        if (audioFavorites.contains(widget.audioId)) {
          // Nếu có, thì xóa khỏi danh sách
          audioFavorites.remove(widget.audioId);
        } else {
          // Nếu chưa, thì thêm vào danh sách
          audioFavorites.add(widget.audioId);
        }

        // Cập nhật lại danh sách audio trong favorites
        favorites['audio'] = audioFavorites;

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
  //fetch audio details from firebase
  Future<void> _fetchAudioDetails() async {
    try {
      // Lấy về một DocumentSnapshot của tài liệu audio cụ thể
      DocumentSnapshot audioSnapshot = await FirebaseFirestore.instance
          .collection('audios')
          .doc(widget.audioId) // Lấy document theo ID của audio
          .get();
      //Lấy ra toàn bộ audio trong collection audios
      QuerySnapshot audiosSnapshot =
          await FirebaseFirestore.instance.collection('audios').get();
      audios = audiosSnapshot.docs;

      if (audioSnapshot.exists) {
        // Lấy dữ liệu từ audioSnapshot
        var data = audioSnapshot.data() as Map<String, dynamic>;

        setState(() {
          title = data['title'];
          imageUrl = data['imageUrl'];
          source = data['source'];
          duration = data['duration'];
          isLoading = false; // Dừng hiển thị trạng thái loading
        });

        //khởi tạo AudioPlayerManager với Url âm thanh sau khi dữ liệu đc load
        _audioPlayerManager = AudioPlayerManager();
        if (_audioPlayerManager.audioUrl.compareTo(source) != 0) {
          _audioPlayerManager.updateAudioUrl(source);
          //Khởi tạo player và các stream
          _audioPlayerManager.prepare(isNewAudio: true);
        } else {
          _audioPlayerManager.prepare(isNewAudio: false);
        }
        // Khởi tạo _selectedAudioIndex dựa trên vị trí của audio hiện tại
        _selectedItemIndex =
            audios.indexWhere((audio) => audio.id == widget.audioId);
        _loopMode = LoopMode.off;

        // Thêm listener để tự động chuyển bài khi kết thúc
        _audioPlayerManager.player.playerStateStream.listen((playerState) {
          if (playerState.processingState == ProcessingState.completed) {
            _setNextSong();
          }
        });

        // In ra dữ liệu để kiểm tra
        print('Document ID: ${audioSnapshot.id}');
        print('Title: ${data['title']}');
        print('Image URL: ${data['imageUrl']}');
        print('Source: ${data['source']}');
        print('Duration: ${data['duration']}');
        print('AudioID = $_selectedItemIndex');
      } else {
        print('Không tìm thấy audio với ID này.');
      }
    } catch (e) {
      print('Lỗi khi lấy chi tiết audio: $e');
    }
  }

  @override
  void dispose() {
    _saveRemainingTime();
    _timer?.cancel();
    AudioPlayerManager().stopAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Playing',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                  const SizedBox(height: 8.0),
                  //display auido image
                  Container(
                    decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.rectangle,
                        boxShadow: [
                          BoxShadow(
                            // Màu bóng
                            color: Colors.grey,
                            spreadRadius: 5,
                            blurRadius: 5,
                            offset: Offset(0, 7), // Vị trí của bóng
                          ),
                        ]),
                    child: Image.network(
                      imageUrl,
                      height: 200.0,
                      width: 150.0,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          // Ảnh thay thế khi bị lỗi connection
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  //display audio title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  //favorite and share button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          _toggleFavorite();
                        },
                        icon: Icon(isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border),
                        color: isFavorite
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        iconSize: 24,
                      ),
                    ],
                  ),
                  // Progress bar and duration
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 8,
                      right: 8,
                      bottom: 16,
                    ),
                    child: _progressBar(),
                  ),

                  //prev play next button
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 8,
                      right: 8,
                      bottom: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () {
                            _setShuffle();
                          },
                          icon: const Icon(Icons.shuffle),
                          color: _getShuffleColor(),
                          iconSize: 20.0,
                        ),
                        IconButton(
                          onPressed: () {
                            _setPrevAudio();
                          },
                          icon: const Icon(Icons.skip_previous),
                          color: Colors.deepPurple,
                          iconSize: 40.0,
                        ),
                        _playButton(),
                        IconButton(
                          onPressed: () {
                            _setNextSong();
                          },
                          icon: const Icon(Icons.skip_next),
                          color: Colors.deepPurple,
                          iconSize: 40.0,
                        ),
                        IconButton(
                          onPressed: () {
                            _setupRepeatOption();
                          },
                          icon: _repeatingIcon(),
                          color: _getRepeatingIconColor(),
                          iconSize: 20.0,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  //nút play
  StreamBuilder _playButton() {
    return StreamBuilder(
      stream: _audioPlayerManager.player.playerStateStream,
      builder: (context, snapshot) {
        final playState = snapshot.data;
        final processingState = playState?.processingState;
        final playing = playState?.playing;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          //đang load
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: 48.0,
            height: 48.0,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          //k phát
          return Container(
            height: 60.0,
            width: 60.0,
            decoration: BoxDecoration(
              color: Colors.deepPurple, // Màu nền cho nút
              shape: BoxShape.circle,
              // Định dạng bo tròn
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5), // Màu bóng
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // Vị trí của bóng
                ),
              ],
            ),
            child: IconButton(
              iconSize: 40.0,
              icon: const Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                _audioPlayerManager.player.play();
              },
            ),
          );
        } else if (processingState != ProcessingState.completed) {
          //đang phát
          return Container(
            height: 60.0,
            width: 60.0,
            decoration: BoxDecoration(
              color: Colors.deepPurple, // Màu nền cho nút
              shape: BoxShape.circle,
              // Định dạng bo tròn
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5), // Màu bóng
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // Vị trí của bóng
                ),
              ],
            ),
            child: IconButton(
              iconSize: 40.0,
              icon: const Icon(
                Icons.pause,
                color: Colors.white,
              ),
              onPressed: () {
                _audioPlayerManager.player.pause();
              },
            ),
          );
        } else {
          return Container(
            height: 80.0,
            width: 80.0,
            decoration: BoxDecoration(
              color: Colors.deepPurple, // Màu nền cho nút
              shape: BoxShape.circle,
              // Định dạng bo tròn
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5), // Màu bóng
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // Vị trí của bóng
                ),
              ],
            ),
            child: IconButton(
              iconSize: 48.0,
              icon: const Icon(
                Icons.replay,
                color: Colors.white,
              ),
              onPressed: () {
                _audioPlayerManager.player.seek(Duration.zero);
              },
            ),
          );
        }
      },
    );
  }

  //thanh progressBar
  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      //Stream trạng thái thời lượng
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        //thời gian đã phát
        final progress = durationState?.progress ?? Duration.zero;
        //thời gian đã bufferd(đã load đc)
        final buffered = durationState?.buffered ?? Duration.zero;
        //tổng thời lượng audio
        final total = durationState?.total ?? Duration.zero;

        return ProgressBar(
          progress: progress,
          buffered: buffered,
          total: total,
          onSeek: _audioPlayerManager.player.seek,
          barHeight: 5.0,
          barCapShape: BarCapShape.round,
          baseBarColor: Colors.grey.withOpacity(0.3),
          progressBarColor: Colors.deepPurple,
          bufferedBarColor: Colors.grey.withOpacity(0.3),
          thumbColor: Colors.deepPurple,
          thumbGlowColor: Colors.purple.withOpacity(0.3),
          thumbRadius: 10.0,
        );
      },
    );
  }

  //shuffle audio
  void _setShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
    });
  }

  Color? _getShuffleColor() {
    return _isShuffle ? Colors.deepPurple : Colors.grey;
  }

  //prev audio
  void _setPrevAudio() {
    setState(() {
      if (_loopMode == LoopMode.one) {
        // Chế độ lặp lại bài hiện tại
        _audioPlayerManager.player.seek(Duration.zero);
      } else if (_isShuffle) {
        // Chế độ shuffle: chọn bài hát ngẫu nhiên
        final random = Random();
        _selectedItemIndex = random.nextInt(audios.length);
      } else {
        // Chế độ phát bình thường hoặc loop all
        _selectedItemIndex--;
        if (_selectedItemIndex < 0) {
          if (_loopMode == LoopMode.all) {
            // Nếu đang ở bài đầu tiên, quay lại bài cuối cùng khi loop all bật
            _selectedItemIndex = audios.length - 1;
          } else {
            // Nếu loop all tắt và ở bài đầu, giữ nguyên ở bài đầu
            _selectedItemIndex = 0;
          }
        }
      }
      // Cập nhật thông tin bài hát
      _updateAudioInfo();
    });
    //lấy url audio trc đó và phát
    final prevAudio = audios[_selectedItemIndex];
    _audioPlayerManager.player.setUrl(prevAudio['source']);
    _audioPlayerManager.player.play();
  }

  //next song
  void _setNextSong() {
    setState(() {
      if (_loopMode == LoopMode.one) {
        // Chế độ lặp lại bài hiện tại
        _audioPlayerManager.player.seek(Duration.zero);
      } else if (_isShuffle) {
        // Chế độ shuffle: chọn bài hát ngẫu nhiên
        final random = Random();
        _selectedItemIndex = random.nextInt(audios.length);
      } else {
        // Chế độ phát bình thường hoặc loop all
        _selectedItemIndex++;
        if (_selectedItemIndex >= audios.length) {
          if (_loopMode == LoopMode.all) {
            // Nếu đang ở bài cuối cùng, quay lại bài đầu tiên khi loop all bật
            _selectedItemIndex = 0;
          } else {
            // Nếu loop all tắt và đến bài cuối, giữ nguyên ở bài cuối
            _selectedItemIndex = audios.length - 1;
          }
        }
      }
      //cập nhật lại vị trí
      _updateAudioInfo();
    });
    //lấy url audio tiếp theo và phát
    final nextAudio = audios[_selectedItemIndex];
    _audioPlayerManager.player.setUrl(nextAudio['source']);
    _audioPlayerManager.player.play();
  }

  //update information audio
  void _updateAudioInfo() {
    final currentAudio =
        audios[_selectedItemIndex].data() as Map<String, dynamic>;
    setState(() {
      title = currentAudio['title'];
      imageUrl = currentAudio['imageUrl'];
      source = currentAudio['source'];
      duration = currentAudio['duration'];
    });
  }

  //loop icon
  Icon _repeatingIcon() {
    if (_loopMode == LoopMode.one) {
      return const Icon(Icons.repeat_one);
    } else if (_loopMode == LoopMode.all) {
      return const Icon(Icons.repeat_on);
    } else {
      return const Icon(Icons.repeat);
    }
  }

  //loop audio
  void _setupRepeatOption() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    setState(() {
      _audioPlayerManager.player.setLoopMode(_loopMode);
    });
  }

  //set màu cho icon loop
  Color? _getRepeatingIconColor() {
    return _loopMode == LoopMode.off ? Colors.grey : Colors.deepPurple;
  }
}

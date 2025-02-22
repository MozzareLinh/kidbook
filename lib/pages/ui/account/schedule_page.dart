import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // Biến lưu thời gian đọc sách
  int _hours = 0; // Giá trị mặc định là 0 giờ
  int _minutes = 0; // Giá trị mặc định là 0 phút
  bool _isLoading = true; // Biến kiểm soát trạng thái đang tải dữ liệu
  // Danh sách các chữ cái cho các thứ trong tuần
  final List<String> weekdays = ['2', '3', '4', '5', '6', '7', 'CN'];
  //Biến lưu thứ đc chọn
  final Set<String> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    _loadSchedule(); // Tải dữ liệu từ Firebase khi mở trang
  }

  //lấy userId của người dùng hiện tại
  String getUserId() {
    User? user = FirebaseAuth.instance.currentUser; // Lấy user hiện tại

    if (user != null) {
      return user.uid; // Trả về userId (uid)
    } else {
      throw Exception("User not logged in");
    }
  }

  //hàm lấy lịch từ firebase
  void _loadSchedule() async {
    String userId = getUserId();
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>;
      if (data.containsKey('duration')) {
        setState(() {
          _hours = data['duration']['hours'] ?? 0;
          _minutes = data['duration']['minutes'] ?? 0;
        });
      }
      if (data.containsKey('schedule')) {
        setState(() {
          _selectedDays.addAll(List<String>.from(data['schedule']));
        });
      }
    }

    // Khi đã tải xong, ngắt loading
    setState(() {
      _isLoading = false;
    });
  }

  //Hàm lưu dữ liệu
  void _saveSchedule() async {
    String userId = getUserId();
    print("id user là $userId");

    Map<String, dynamic> scheduleData = {
      'duration': {
        'hours': _hours,
        'minutes': _minutes,
      },
      'schedule': _selectedDays.toList(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(scheduleData)
        .then((_) {
      print("Lịch đã được lưu.");
    }).catchError((error) {
      print("Lỗi khi lưu lịch: $error");
    });
  }

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Text(
                    'Chọn thời gian đọc sách',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _saveSchedule();
                    },
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 2),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Giờ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 70,
                          height: 200,
                          child: _buildInfiniteScrollWheel(
                            24,
                            _hours,
                                (value) => setState(() => _hours = value),
                            '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Phút',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 70,
                          height: 200,
                          child: _buildInfiniteScrollWheel(
                            60,
                            _minutes,
                                (value) => setState(() => _minutes = value),
                            '',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfiniteScrollWheel(
      int itemCount, int selectedItem, Function(int) onChanged, String suffix) {
    final FixedExtentScrollController scrollController =
    FixedExtentScrollController(
      initialItem: selectedItem + itemCount * 1000,
    );

    return Stack(
      children: [
        ListWheelScrollView.useDelegate(
          itemExtent: 50,
          perspective: 0.005,
          diameterRatio: 1.2,
          controller: scrollController,
          onSelectedItemChanged: (index) {
            final actualIndex = index % itemCount;
            onChanged(actualIndex);
          },
          childDelegate: ListWheelChildLoopingListDelegate(
            children: List.generate(itemCount, (index) {
              return Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: index == selectedItem ? 24 : 18,
                    fontWeight:
                    index == selectedItem ? FontWeight.bold : FontWeight.normal,
                    color: index == selectedItem
                        ? Colors.deepPurple
                        : Colors.black,
                  ),
                  child: Text(index.toString().padLeft(2, '0') + suffix),
                ),
              );
            }),
          ),
        ),
        Center(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Hàm sắp xếp các ngày
  List<String> _sortDays(List<String> days) {
    // Danh sách thứ tự từ T2 đến CN
    const List<String> order = ['2', '3', '4', '5', '6', '7', 'CN'];

    // Sắp xếp lại danh sách dựa trên thứ tự
    days.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thiết lập thời gian đọc',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Hiển thị biểu tượng loading
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Khoảng thời gian đọc sách trong ngày",
                    style: TextStyle(
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: _showTimePicker,
                    child: Container(
                      height: 80,
                      width: 700,
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        bottom: 8.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20.0, 8, 20.0, 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.watch_later_outlined,
                              size: 16.0,
                            ),
                            const SizedBox(width: 15.0),
                            const Text(
                              'Thời gian đọc',
                              style: TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _minutes == 0
                                  // Chỉ hiển thị giờ nếu phút = 0
                                  ? '${_hours.toString().padLeft(1)} h'
                                  // Hiển thị giờ và phút
                                  : '${_hours.toString().padLeft(1)}h : ${_minutes.toString().padLeft(2, '0')}p',
                              style: const TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(width: 5.0),
                            const Icon(Icons.arrow_forward_ios_outlined, size: 14,),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25.0),
                  const Text(
                    "Bạn sẽ đọc sách vào những ngày nào?",
                    style: TextStyle(
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Container(
                    height: 180,
                    width: 700,
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 8.0,
                    ),
                    child: Container(
                        padding: const EdgeInsets.only( top: 8.0, bottom: 8.0,),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const SizedBox(width: 20.0),
                                Text(
                                  _selectedDays.length == 7
                                      ? 'Mỗi ngày'
                                      : _selectedDays.isNotEmpty
                                          ? 'Mỗi ${_sortDays(_selectedDays.toList()).map((day) {
                                                return day == 'CN'
                                                    ? 'CN'
                                                    : 'T$day';
                                              }).toList().join(', ')}'
                                          : '',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 20.0,
                                ),
                                const SizedBox(width: 20.0),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            Wrap(
                              spacing: 8.0,
                              children: weekdays.map((day) {
                                final isSelected = _selectedDays.contains(day);
                                return FilterChip(
                                  label: Text(day),
                                  selected: isSelected,
                                  // Màu nền khi chưa chọn
                                  backgroundColor: Colors.white,
                                  // Màu nền khi đã chọn
                                  selectedColor: Colors.deepPurple[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                    side: isSelected
                                        // Viền khi đã chọn
                                        ? const BorderSide(
                                            color: Colors.deepPurple,
                                            width: 1.0,
                                          )
                                        // Không có viền khi chưa chọn
                                        : BorderSide.none,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedDays.add(day);
                                      } else {
                                        _selectedDays.remove(day);
                                      }
                                    });
                                    _saveSchedule();
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        )),
                  )
                ],
              ),
            ),
    );
  }
}

import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Screens/FriendScreen.dart';
import 'package:chatapp/Screens/NotificationPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Screens/PersonalInfo.dart';
import 'package:chatapp/Pages/ChatPage.dart';
import 'package:chatapp/Pages/StatusPage.dart';
import 'package:chatapp/Services/api.dart';
import 'package:chatapp/Screens/IndividualPage.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key, required this.sourchat}) : super(key: key);
  final Chat sourchat;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Default to Chat page
  String? _token;
  Map<String, dynamic>? _searchedUser;
  bool _isSearching = false;
  final TextEditingController _phoneNumberController = TextEditingController();
  final Api api = Api(); // Khởi tạo đối tượng Api
  String? _userId; // Thêm biến để lưu userId

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      _userId = prefs.getString('userId'); // Tải userId từ SharedPreferences

    });
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PersonalInfo()),
      ).then((_) {
        // Khi trở lại trang HomeScreen, có thể cần làm mới dữ liệu hoặc kiểm tra trạng thái người dùng
        _loadToken();
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _searchUserByPhoneNumber(String phoneNumber) async {
    if (_token == null) {
      return; // Không làm gì nếu token chưa được tải
    }

    final result = await api.searchUserByPhoneNumber(phoneNumber, _token!);

    setState(() {
      if (result['success']) {
        _searchedUser = result['user'];
        _searchedUser!['chat'] = result['chat']; // Include chat information
        _showSearchResultDialog(_searchedUser!);
      } else {
        _searchedUser = null;
        // Hiển thị thông báo lỗi nếu có
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    });
  }

  void _showSearchResultDialog(Map<String, dynamic> user) async {
    bool isFriend = false;
    if (_token != null) {
      final friendshipStatus = await api.checkFriendship(user['_id'], _token!);
      if (friendshipStatus['success']) {
        isFriend = friendshipStatus['message'] == 'Users are friends.';
      }
      // Log the friendship status and user IDs
      print('User ID đang đăng nhập: $_userId');
      print('User ID được tìm kiếm: ${user['_id']}');
      print('Is friend: $isFriend');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            height: 300, // Adjust the height as needed
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      height:
                          150, // Adjust the height to cover half of the avatar
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/images.jpg'), // Add your background image here
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 80, // Adjust the position to place the avatar correctly
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundImage: user['avatar'] != null
                            ? NetworkImage(user['avatar'])
                            : AssetImage('assets/default_avatar.jpg')
                                as ImageProvider,
                        radius: 50,
                      ),
                      SizedBox(height: 10),
                      Text(
                        user['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: Icon(Icons.message, color: Colors.black),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              if (user['chat'] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IndividualPage(
                                      sId: user['chat']['_id'],
                                      receiverName: user['name'],
                                    ),
                                  ),
                                );
                              } else {
                                final newChat = await api.createChat(
                                    widget.sourchat.userId!,
                                    user['_id'],
                                    _token!);
                                if (newChat['success']) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IndividualPage(
                                        sId: newChat['chat']['_id'],
                                        receiverName: user['name'],
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(newChat['message'])),
                                  );
                                }
                              }
                            },
                          ),
                          if (!isFriend)
                            IconButton(
                              icon: Icon(Icons.person_add, color: Colors.black),
                              onPressed: () async {
                                final friendRequest = await api
                                    .sendFriendRequest(user['_id'], _token!);
                                if (friendRequest['success']) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Friend request sent successfully')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text(friendRequest['message'])),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user['avatar'] != null
            ? NetworkImage(user['avatar'])
            : AssetImage('assets/default_avatar.jpg') as ImageProvider,
        radius: 25,
      ),
      title: Text(
        user['name'] ?? 'Unknown',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        user['phoneNumber'] ?? 'Unknown',
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
      onTap: () async {
        if (user['chat'] != null) {
          // Navigate to existing chat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualPage(
                  sId: user['chat']['_id'], receiverName: user['name']),
            ),
          );
        } else {
          // Create a new chat
          final newChat = await api.createChat(
              widget.sourchat.userId!, user['_id'], _token!);
          if (newChat['success']) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualPage(
                    sId: newChat['chat']['_id'], receiverName: user['name']),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(newChat['message'])),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      ChatPage(sourchat: widget.sourchat),
      StatusPage(),
      FriendScreen(sourchat: widget.sourchat),
    ];

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black),
                ),
                style: TextStyle(color: Colors.black),
                autofocus: true,
                keyboardType: TextInputType.phone,
                onSubmitted: (value) {
                  _searchUserByPhoneNumber(value);
                  setState(() {
                    _isSearching = false;
                  });
                },
              )
            : Text("Whisper"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _phoneNumberController.clear();
                  _searchedUser = null;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
        ],
        backgroundColor: Color(0xFF0084FF), // Màu xanh của Zalo
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedIndex == 3
                ? SizedBox
                    .shrink() // Prevent rendering any content for the 'Calls' tab when it’s not used
                : _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.messenger,
                  color: _selectedIndex == 0 ? Color(0xFFFFDD4D) : Colors.grey),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(Icons.access_time,
                  color: _selectedIndex == 1 ? Color(0xFFFFDD4D) : Colors.grey),
              onPressed: () => _onItemTapped(1),
            ),
            IconButton(
              icon: Icon(Icons.list,
                  color: _selectedIndex == 2 ? Color(0xFFFFDD4D) : Colors.grey),
              onPressed: () => _onItemTapped(2),
            ),
            IconButton(
              icon: Icon(Icons.person_pin_rounded,
                  color: _selectedIndex == 3 ? Color(0xFFFFDD4D) : Colors.grey),
              onPressed: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}

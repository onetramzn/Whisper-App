import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/UserModel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'EditProfilePage.dart';
import 'LoginScreen.dart';
import '../Services/api.dart'; // Nhập đối tượng Api

// Định nghĩa URL cơ sở cho API
const String baseUrl = 'http://localhost:5000/api';

class PersonalInfo extends StatefulWidget {
  @override
  _PersonalInfoState createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  User? _user;
  bool _isLoading = true;
  final Api api = Api(); // Khởi tạo đối tượng Api

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    String? token = await _getToken();
    if (token != null) {
      final result = await getCurrentUserProfile(token);
      if (result['success']) {
        setState(() {
          _user = User.fromJson(result['profile']);
          _isLoading = false;
        });
      } else {
        _showErrorSnackbar(
            result['message'] ?? 'Failed to load user information');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _showErrorSnackbar('Token is not available. Please login again.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getCurrentUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Thêm token vào header để xác thực
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'profile': jsonDecode(response.body)};
    } else {
      final responseBody = jsonDecode(response.body);
      return {'success': false, 'message': responseBody['message']};
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signOut() async {
    String? token = await _getToken();
    if (token != null) {
      final result =
          await api.logout(token); // Sử dụng phương thức logout từ api.dart
      if (result['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('userId');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  LoginScreen()), // Điều hướng đến trang đăng nhập
          (route) =>
              false, // Xóa tất cả các trang trước đó khỏi lịch sử điều hướng
        );
      } else {
        _showErrorSnackbar(result['message'] ?? 'Failed to sign out');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin cá nhân'),
        backgroundColor: Color(0xFFFFDD4D),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(child: Text('Failed to load user information.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(_user!.avatar),
                        backgroundColor: Colors.black,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user!.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          User? updatedUser = await Navigator.push<User>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfilePage(user: _user!),
                            ),
                          );
                          if (updatedUser != null) {
                            setState(() {
                              _user = updatedUser;
                            });
                          }
                        },
                        child: Text(
                          'Chỉnh sửa thông tin',
                          style: TextStyle(
                            color: Colors.blue, // Màu chữ xanh
                            fontSize: 16, // Kích thước chữ
                            fontWeight: FontWeight.bold, // Đậm
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Danh sách các nút chức năng
                      Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.security, color: Colors.black),
                            title: Text(
                              'Bảo mật',
                              style: TextStyle(
                                  color:
                                      Colors.black), // Màu chữ trong ListTile
                            ),
                            onTap: () {
                              // Xử lý sự kiện khi nhấn nút Bảo mật
                            },
                          ),
                          Divider(
                              height: 1,
                              color: Colors.grey[800]), // Đường kẻ ngăn cách
                          ListTile(
                            leading:
                                Icon(Icons.notifications, color: Colors.black),
                            title: Text(
                              'Thông báo',
                              style: TextStyle(
                                  color:
                                      Colors.black), // Màu chữ trong ListTile
                            ),
                            onTap: () {
                              // Xử lý sự kiện khi nhấn nút Thông báo
                            },
                          ),
                          Divider(
                              height: 1,
                              color: Colors.grey[800]), // Đường kẻ ngăn cách
                          ListTile(
                            leading: Icon(Icons.help, color: Colors.black),
                            title: Text(
                              'Hỗ trợ',
                              style: TextStyle(
                                  color:
                                      Colors.black), // Màu chữ trong ListTile
                            ),
                            onTap: () {
                              // Xử lý sự kiện khi nhấn nút Hỗ trợ
                            },
                          ),
                          Divider(
                              height: 1,
                              color: Colors.grey[800]), // Đường kẻ ngăn cách
                          ListTile(
                            leading: Icon(Icons.settings, color: Colors.black),
                            title: Text(
                              'Cài đặt',
                              style: TextStyle(
                                  color:
                                      Colors.black), // Màu chữ trong ListTile
                            ),
                            onTap: () {
                              // Xử lý sự kiện khi nhấn nút Cài đặt
                            },
                          ),
                          Divider(
                              height: 1,
                              color: Colors.grey[800]), // Đường kẻ ngăn cách
                          ListTile(
                            leading: Icon(Icons.logout, color: Colors.black),
                            title: Text(
                              'Đăng xuất',
                              style: TextStyle(
                                  color:
                                      Colors.black), // Màu chữ trong ListTile
                            ),
                            onTap: () {
                              _signOut(); // Xử lý sự kiện khi nhấn nút Cài đặt
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

import 'package:chatapp/Model/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Services/api.dart';
import 'package:chatapp/Screens/IndividualPage.dart';

class FriendScreen extends StatefulWidget {
  FriendScreen({Key? key, required this.sourchat}) : super(key: key);
  final Chat sourchat;

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  List<Map<String, dynamic>> _friends = [];
  String? _token;
  final Api api = Api();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  String? _userId;

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      _userId = prefs.getString('userId'); // Load userId
    });
    if (_token != null) {
      _fetchFriends();
    }
  }

  Future<void> _fetchFriends() async {
    final result = await api.getFriendsList(_token!);
    if (result['success']) {
      setState(() {
        _friends = List<Map<String, dynamic>>.from(result['friends']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  void _navigateToChat(Map<String, dynamic> friend) async {
    print('User ID: $_userId'); // Log userId to the console
    print('Friend ID: ${friend['_id']}'); // Log friend ID to the console
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID is not available')),
      );
      return;
    }

    final chatResult = await api.createChat(_userId!, friend['_id'], _token!);
    if (chatResult['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IndividualPage(
            sId: chatResult['chat']['_id'],
            receiverName: friend['name'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(chatResult['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
        backgroundColor: Color(0xFF0084FF),
      ),
      body: _friends.isEmpty
          ? Center(child: Text('No friends found'))
          : ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundImage: friend['avatar'] != null
                            ? NetworkImage(friend['avatar'])
                            : AssetImage('assets/default_avatar.jpg')
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: friend['status'] == 'online'
                                ? Colors.green
                                : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(friend['name'] ?? 'Unknown'),
                  subtitle: Text(friend['phoneNumber'] ?? 'Unknown'),
                  onTap: () => _navigateToChat(friend),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Services/api.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _friendRequests = [];
  String? _token;
  final Api api = Api();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
    if (_token != null) {
      _fetchFriendRequests();
    }
  }

  Future<void> _fetchFriendRequests() async {
    final result = await api.getFriendRequests(_token!);
    if (result['success']) {
      setState(() {
        _friendRequests = List<Map<String, dynamic>>.from(result['friendRequests'] as List);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _acceptFriendRequest(String requestId) async {
    final result = await api.acceptFriendRequest(requestId, _token!);
    if (result['success']) {
      _fetchFriendRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request accepted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    final result = await api.rejectFriendRequest(requestId, _token!);
    if (result['success']) {
      _fetchFriendRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request rejected successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Color(0xFF0084FF),
      ),
      body: _friendRequests.isEmpty
          ? Center(child: Text('No friend requests'))
          : ListView.builder(
              itemCount: _friendRequests.length,
              itemBuilder: (context, index) {
                final request = _friendRequests[index];
                final requester = request['requester'];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: requester['avatar'] != null
                        ? NetworkImage(requester['avatar'])
                        : AssetImage('assets/default_avatar.jpg') as ImageProvider,
                  ),
                  title: Text(requester['name'] ?? 'Unknown'),
                  subtitle: Text(requester['phoneNumber'] ?? 'Unknown'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptFriendRequest(request['_id']),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectFriendRequest(request['_id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
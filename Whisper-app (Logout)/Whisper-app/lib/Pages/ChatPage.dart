import 'package:chatapp/Screens/IndividualPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/ChatModel.dart';
import '../Services/api.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatPage extends StatefulWidget {
  final Chat sourchat;

  ChatPage({Key? key, required this.sourchat}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Chats> chatModels = [];
  bool _isLoading = true;
  String? _errorMessage;
  late IO.Socket _socket;
  late Api _api;
  late String currentUserId;
  Map<String, String> nicknames = {}; // Add this line for nicknames

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchChats();
    _loadNicknames(); // Load nicknames from SharedPreferences
  }

  void _initializeSocket() async {
    _socket = IO.io('http://localhost:5000',
        IO.OptionBuilder().setTransports(['websocket', 'polling']).build());

    _socket.on('connect', (_) {
      print('Connected to socket server');
    });

    _socket.on('disconnect', (_) {
      print('Disconnected from socket server');
    });

    _socket.on('newMessage', (message) {
      print('New message received: $message');
      setState(() {
        _fetchChats(); // Update chat list on new message
      });
    });

    _api = Api(); // Initialize Api with Socket

    // Get current user ID
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId =
        prefs.getString('userId') ?? 'defaultUserId'; // Get current user ID
  }

  Future<void> _fetchChats() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Token is not available. Please login again.';
        });
        return;
      }

      final result = await _api.getChatsByUser(token);

      if (result['success']) {
        final List<dynamic> data = result['chats'];
        setState(() {
          chatModels = data
              .map((chat) => Chats.fromJson(chat as Map<String, dynamic>))
              .toList();
          _isLoading = false;
          _loadNicknames(); // Load nicknames after fetching chats
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load chats: ${result['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _loadNicknames() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var chat in chatModels) {
      final nickname = prefs.getString('nickname_${chat.sId}');
      if (nickname != null) {
        setState(() {
          nicknames[chat.sId!] = nickname; // Update state with nicknames
        });
      }
    }
  }

  Future<void> _deleteChat(String chatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final result = await _api.deleteChat(chatId, token);

      // Log the result of the API call
      print('API deleteChat result: $result');

      if (result['success']) {
        setState(() {
          chatModels.removeWhere((chat) => chat.sId == chatId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete chat: ${result['message']}')),
        );
      }
    } else {
      print('Token is null');
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(String chatId) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xoá đoạn chat này không?'),
          actions: <Widget>[
            TextButton(
              child: Text('Huỷ'),
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Close the dialog and return false
              },
            ),
            TextButton(
              child: Text('Xoá'),
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // Close the dialog and return true
              },
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : ListView.builder(
                itemCount: chatModels.length,
                itemBuilder: (context, index) {
                  final chat = chatModels[index];
                  final lastMessage = chat.lastMessage;
                  final lastMessageContent =
                      lastMessage?.content ?? 'No message';
                  final lastTimeMessage = lastMessage?.createdAt ?? 'Unknown';

                  // Format the createdAt date
                  String formattedTime;
                  try {
                    final DateTime dateTime = DateTime.parse(lastTimeMessage);
                    final localDateTime = dateTime.toLocal();
                    formattedTime = DateFormat('HH:mm').format(localDateTime);
                  } catch (e) {
                    formattedTime = 'Unknown';
                  }

                  // Get the receiver's name and avatar
                  final receiver = chat.participants?.firstWhere(
                      (participant) => participant.sId != currentUserId,
                      orElse: () => Participants(name: 'Unknown', avatar: null, status: 'offline'));
                  final receiverName = receiver?.name ?? 'Unknown';
                  final receiverAvatar = receiver?.avatar;
                  final receiverStatus = receiver?.status ?? 'offline'; // Get receiver's status

                  // Check for nickname
                  final nickname = nicknames[chat.sId] ?? receiverName;

                  // Determine if the last message was sent by the current user
                  final isSentByCurrentUser =
                      lastMessage?.sender == currentUserId;
                  final displayMessageContent = isSentByCurrentUser
                      ? 'Bạn: $lastMessageContent'
                      : lastMessageContent;

                  return Dismissible(
                    key: Key(chat.sId ?? ''),
                    background: Container(
                      color: Colors.red,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      // Show confirmation dialog
                      final shouldDelete =
                          await _showDeleteConfirmationDialog(chat.sId ?? '');

                      if (shouldDelete == true) {
                        // Call _deleteChat if the user confirmed deletion
                        await _deleteChat(chat.sId ?? '');
                        return true; // Dismiss the item
                      } else {
                        return false; // Do not dismiss the item
                      }
                    },
                    child: Column(
                      children: [
                        ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                backgroundImage: receiverAvatar != null
                                    ? NetworkImage(receiverAvatar)
                                    : AssetImage('assets/default_avatar.jpg')
                                        as ImageProvider,
                                radius: 25,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: receiverStatus == 'online'
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
                          title: Text(
                            nickname, // Use nickname instead of receiverName
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text('$displayMessageContent'),
                          trailing: Text(formattedTime),
                          onTap: () {
                            if (chat.sId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IndividualPage(
                                    sId: chat.sId!,
                                    receiverName: nickname,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        if (index < chatModels.length - 1) // Add divider only if it's not the last item
                          Divider(height: 1, color: Colors.grey),
                      ],
                    ),
                  );
                },
              ),
  );
}
}

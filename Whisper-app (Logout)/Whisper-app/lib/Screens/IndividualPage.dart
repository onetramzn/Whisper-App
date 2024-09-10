import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/Model/MessageModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Services/api.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../Pages/CameraPage.dart'; // Import CameraPage

class IndividualPage extends StatefulWidget {
  final String sId;
  final String receiverName;

  IndividualPage({required this.sId, required this.receiverName});

  @override
  _IndividualPageState createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  String _nickname = '';

  late Api _api;
  List<Data> messages = [];
  bool isLoading = true;
  late SharedPreferences prefs;
  late String currentUserId;
  bool showEmojiPicker = false;
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  late IO.Socket socket;
  bool isCameraOpen = false;
  String _backgroundImage =
      'assets/background/chatbg.jpg'; // Default background image

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    // Initialize SocketService and Api
    socket = IO.io('http://192.168.2.7:5000',
        IO.OptionBuilder().setTransports(['websocket']).build());
    _api = Api();

    // Connect to socket
    socket.connect();

    // Join chat on socket connection
    socket.emit('joinChat', widget.sId);

    // Listen for new messages
    socket.on('message', (data) {
      if (data['chatId'] == widget.sId) {
        setState(() {
          messages.add(Data.fromJson(data));
          // Scroll to the bottom after receiving a new message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId') ?? "defaultUserId";
    String backgroundImage =
        prefs.getString('background') ?? 'assets/background/chatbg.jpg';
    String nickname = prefs.getString('nickname_${widget.sId}') ?? '';
    setState(() {
      _backgroundImage = backgroundImage;
      _nickname = nickname;
    });
    _fetchMessages();
  }

  void _showNicknameDialog() {
    TextEditingController nicknameController =
        TextEditingController(text: _nickname);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đặt biệt hiệu'),
          content: TextField(
            controller: nicknameController,
            decoration: InputDecoration(hintText: 'Nhập biệt hiệu mới'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _nickname = nicknameController.text;
                });
                await prefs.setString('nickname_${widget.sId}', _nickname);
                Navigator.pop(context);
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveNicknameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xóa biệt hiệu'),
          content: Text(
              'Bạn có chắc chắn muốn xóa biệt hiệu và quay lại tên gốc không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _nickname =
                      widget.receiverName; // Revert to the original name
                });
                await prefs.remove('nickname_${widget.sId}');
                Navigator.pop(context);
              },
              child: Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchMessages() async {
    try {
      final result = await _api.getMessagesByChat(widget.sId);
      setState(() {
        isLoading = false;
        if (result['success']) {
          messages = (result['data'] as List)
              .map((item) => Data.fromJson(item))
              .toList();
          // Scroll to the bottom after data is loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else {
          _showError(result['message']);
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('An error occurred while fetching messages.');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _sendMessage(String messageContent) async {
    if (messageContent.isEmpty) return;
    final createdAt = DateTime.now().toIso8601String();

    setState(() {
      isLoading = true;
    });

    try {
      final response = await _api.createMessage(
        chatId: widget.sId,
        senderId: currentUserId,
        content: messageContent,
        type: 'text',
        fileUrl: null,
      );

      if (response['success']) {
        final messageData = response['data'];

        setState(() {
          messages.add(
            Data(
              sId: messageData['_id'],
              chat: messageData['chat'],
              sender: Sender(sId: messageData['sender']),
              content: messageData['content'],
              type: messageData['type'],
              fileUrl: messageData['fileUrl'],
              createdAt: createdAt,
              updatedAt: messageData['updatedAt'],
            ),
          );
          _controller.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });

        socket.emit('newMessage', {
          'chatId': widget.sId,
          'senderId': currentUserId,
          'content': messageContent,
          'createdAt': createdAt,
          'type': 'text',
          'fileUrl': null,
        });
      } else {
        _showError(response['message']);
      }
    } catch (e) {
      _showError('An error occurred while sending the message.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openCameraPage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // Remove dialog padding
          child: Stack(
            children: [
              CameraPage(
                onClose: () {
                  Navigator.pop(context); // Close dialog when user clicks "X"
                  setState(() {
                    isCameraOpen = false;
                  });
                },
              ),
              Positioned(
                top: 20, // Adjust top distance if needed
                right: 20, // Adjust right distance if needed
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog when user clicks "X"
                    setState(() {
                      isCameraOpen = false;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    setState(() {
      isCameraOpen = true;
    });
  }

  void _showChangeBackgroundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thay đổi ảnh nền'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBackgroundOption(
                    'assets/background/chatbg.jpg', 'Default'),
                _buildBackgroundOption(
                    'assets/background/chatbg2.jpg', 'Background 2'),
                _buildBackgroundOption(
                    'assets/background/chatbg3.jpg', 'Background 3'),
                _buildBackgroundOption(
                    'assets/background/chatbg4.jpg', 'Background 4'),
                _buildBackgroundOption(
                    'assets/background/chatbg5.jpg', 'Background 5'),
                // Add more options here
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundOption(String assetPath, String label) {
    return ListTile(
      leading: Image.asset(assetPath, width: 50, height: 50, fit: BoxFit.cover),
      title: Text(label),
      onTap: () {
        _updateBackground(assetPath);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _updateBackground(String assetPath) async {
    setState(() {
      _backgroundImage = assetPath;
    });
    await prefs.setString('background', assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nickname.isEmpty ? widget.receiverName : _nickname),
        backgroundColor: Color(0xFFFFDD4D),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'nickname':
                  _showNicknameDialog();
                  break;
                case 'remove_nickname':
                  _showRemoveNicknameDialog();
                  break;
                case 'background':
                  _showChangeBackgroundDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'nickname',
                child: Text('Đặt biệt hiệu'),
              ),
              const PopupMenuItem<String>(
                value: 'remove_nickname',
                child: Text('Xóa biệt hiệu'),
              ),
              const PopupMenuItem<String>(
                value: 'background',
                child: Text('Đổi nền'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? Center(child: Text('Không có tin nhắn.'))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isSentByCurrentUser =
                                message.sender?.sId == currentUserId;

                            // Format the createdAt date
                            String formattedTime;
                            try {
                              final DateTime dateTime =
                                  DateTime.parse(message.createdAt ?? '');
                              final localDateTime = dateTime.toLocal();
                              formattedTime =
                                  DateFormat('HH:mm').format(localDateTime);
                            } catch (e) {
                              formattedTime = 'Unknown';
                            }

                            return Align(
                              alignment: isSentByCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSentByCurrentUser
                                      ? Colors.black
                                      : Color(0xFFFFDD4D),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: isSentByCurrentUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content ?? 'No content',
                                      style: TextStyle(
                                        color: isSentByCurrentUser
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                        color: isSentByCurrentUser
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (showEmojiPicker) _buildEmojiPicker(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(showEmojiPicker
                    ? Icons.keyboard
                    : Icons.emoji_emotions_outlined),
                onPressed: () {
                  setState(() {
                    showEmojiPicker = !showEmojiPicker;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.black),
                onPressed: _openCameraPage, // Open CameraPage
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Soạn tin nhắn',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                    ),
                    onTap: () {
                      setState(() {
                        showEmojiPicker = false;
                      });
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.black),
                onPressed: () {
                  _sendMessage(_controller.text);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        setState(() {
          _controller.text += emoji.emoji;
        });
      },
    );
  }
}

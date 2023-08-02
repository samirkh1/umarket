import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:umarket/chat/chat_service.dart';


class ChatPage extends StatefulWidget {
  final String userName;
  final String receiverUserID;
  const ChatPage({
    Key? key, // Use 'Key?' instead of 'super.key'
    required this.receiverUserID,
    required this.userName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void sendMessage() async {
    String transfer = _messageController.text;
    _messageController.clear();
    if (transfer != "") {
      await _chatService.sendMessage(widget.receiverUserID, transfer);
      transfer = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userName)),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8, bottom: 8), // Adjust the spacing here
            child: _buildMessageInput(),
          ),
        ],
      ),
    );
  }
  
  // build message list
  Widget _buildMessageList() {
  return StreamBuilder(
    stream: _chatService.getMessages(widget.receiverUserID, _firebaseAuth.currentUser!.uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text('Error${snapshot.error}');
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text('Loading...');
      }

      List<DocumentSnapshot> messages = snapshot.data!.docs;

      return ListView.builder(
        itemCount: messages.length,
        reverse: true, // Display the latest messages at the bottom
        itemBuilder: (context, index) {
          return _buildMessageItem(messages[messages.length - index - 1]);
        },
      );
    },
  );
}

  // build message item
  // build message item
Widget _buildMessageItem(DocumentSnapshot document) {
  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
  bool isCurrentUser = data['senderId'] == _firebaseAuth.currentUser!.uid;

  Timestamp timestamp = data['timestamp'];
  DateTime messageTime = timestamp.toDate();

  // Get the current date and time
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);

  String timeText;
  if (messageTime.isAfter(today.subtract(Duration(days: 6)))) {
    // If the message was sent within the last week, display the day name (e.g., "Monday", "Tuesday", etc.)
    timeText = _getDayName(messageTime);
  } else if (messageTime.isAfter(today.subtract(Duration(days: 13)))) {
    // If the message was sent more than a week ago but within the last two weeks, display "Last Week"
    timeText = "Last Week";
  } else {
    // If the message was sent more than two weeks ago, display the date (e.g., "2023-07-15")
    timeText = "${messageTime.year}-${messageTime.month.toString().padLeft(2, '0')}-${messageTime.day.toString().padLeft(2, '0')}";
  }

  // Check if the message was sent on the same day
  if (messageTime.isAfter(DateTime(now.year, now.month, now.day))) {
    // Calculate the time difference in minutes
    int minutesDifference = now.difference(messageTime).inMinutes;
    // Display the time difference in minutes
    timeText = "$minutesDifference min ago";
  }

  return Align(
    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['message'],
            style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            timeText,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

// Helper method to get the day name (e.g., "Monday", "Tuesday", etc.)
String _getDayName(DateTime dateTime) {
  List<String> dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  int dayIndex = dateTime.weekday - 1;
  return dayNames[dayIndex];
}


  // build message input
  // build message input
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Enter Message',
                border: OutlineInputBorder(),
              ),
              obscureText: false,
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(
              Icons.send,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

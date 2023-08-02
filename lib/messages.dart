import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'chat_page.dart';

class Messages extends StatefulWidget {
  const Messages({Key? key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messages"),
        backgroundColor: Colors.blue, // Use a modern color for the app bar
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(
          child: Text('Error'),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(), // Use a modern loading indicator
        );
      }

      // Extract the data from the current user's document
      Map<String, dynamic> currentUserData = snapshot.data!.data() as Map<String, dynamic>;
      List<String> messagedUsers = [];
      if (currentUserData.containsKey('messagedUsers')) {
        messagedUsers = List.from(currentUserData['messagedUsers']);
      }

      // Fetch the 'users' collection as a QuerySnapshot
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(), // Use a modern loading indicator
            );
          }

          // Filter users based on messagedUsers array
          List<DocumentSnapshot> users = snapshot.data!.docs.where((doc) {
            Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
            return _auth.currentUser!.uid != data['uid'] && messagedUsers.contains(data['uid']);
          }).toList();

          return FutureBuilder<Map<String, Timestamp?>>(
            future: _getMostRecentTimestamps(users),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(), // Use a modern loading indicator
                );
              }

              // Sort users based on most recent message timestamp
              users.sort((a, b) {
                String userUID1 = a['uid'];
                String userUID2 = b['uid'];
                Timestamp? timestamp1 = snapshot.data?[userUID1];
                Timestamp? timestamp2 = snapshot.data?[userUID2];

                if (timestamp1 == null || timestamp2 == null) {
                  // Handle the case where one or both users have no messages
                  return 0;
                }

                return timestamp2.compareTo(timestamp1);
              });

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildUserListItem(users[index]);
                },
              );
            },
          );
        },
      );
    },
  );
}

Future<Map<String, Timestamp?>> _getMostRecentTimestamps(List<DocumentSnapshot> users) async {
  Map<String, Timestamp?> timestamps = {};
  for (var user in users) {
    String userUID = user['uid'];
    String chatRoomId = _createChatRoomId(_auth.currentUser!.uid, userUID);
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: true).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      Map<String, dynamic>? messageData = snapshot.docs.first.data() as Map<String, dynamic>?;
      timestamps[userUID] = messageData?['timestamp'];
    } else {
      timestamps[userUID] = null;
    }
  }
  return timestamps;
}

  Widget _buildUserListItem(DocumentSnapshot document) {
  Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
  String userUID = data['uid'];

  if (_auth.currentUser!.uid != userUID) {
    // Get the most recent message from the chat_rooms collection
    String chatRoomId = _createChatRoomId(_auth.currentUser!.uid, userUID);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: true).limit(1).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(), // Use a modern loading indicator
          );
        }

        // Get the most recent message for the chat_room
        var mostRecentMessage = snapshot.data!.docs.isNotEmpty ? snapshot.data!.docs.first : null;
        Map<String, dynamic>? messageData = mostRecentMessage?.data() as Map<String, dynamic>?;

        return ListTile(
          title: Text(
            data['name'],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: messageData != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        messageData['message'],
                        maxLines: 2, // Limit text to 2 lines
                        overflow: TextOverflow.ellipsis, // Show '...' when text overflows
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600], // Use a modern color for the message text
                        ),
                      ),
                    ),
                    Text(
                      _getFormattedTimestamp(messageData['timestamp']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600], // Use a modern color for the timestamp text
                      ),
                    ),
                  ],
                )
              : null,
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300], // Use a modern color for the avatar background
            child: Text(
              data['name'][0],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverUserID: userUID,
                userName: data['name'],
              ),
            ),
          );
          // After returning from ChatPage, trigger a reload of the user list
          setState(() {});
        },
        );
      },
    );
  } else {
    return Container();
  }
}

  String _createChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join("_");
  }

  String _getFormattedTimestamp(Timestamp timestamp) {
    DateTime now = DateTime.now();
    DateTime messageTime = timestamp.toDate();

    if (now.year == messageTime.year && now.month == messageTime.month && now.day == messageTime.day) {
      // Today, show time with AM/PM
      return DateFormat('h:mm a').format(messageTime);
    } else if (now.year == messageTime.year && now.month == messageTime.month && now.day - messageTime.day == 1) {
      // Yesterday, show 'Yesterday'
      return 'Yesterday';
    } else if (now.year == messageTime.year && now.difference(messageTime).inDays < 7) {
      // Within the last week, show day name
      return DateFormat('EEEE').format(messageTime);
    } else {
      // More than a week ago, show date in the format mm/dd/yy
      return DateFormat('MM/dd/yy').format(messageTime);
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/message.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  Future<void> sendMessage(String receiverId, String message) async {
  final String currentUserId = _firebaseAuth.currentUser!.uid;
  final String currentUserName = _firebaseAuth.currentUser!.displayName.toString();
  final Timestamp timestamp = Timestamp.now();

  Message newMessage = Message(
    senderId: currentUserId,
    senderName: currentUserName,
    receiverId: receiverId,
    timestamp: timestamp,
    message: message,
  );

  List<String> ids = [currentUserId, receiverId];
  ids.sort();
  String chatRoomId = ids.join("_");

  await _fireStore
    .collection('chat_rooms')
    .doc(chatRoomId)
    .collection('messages')
    .add(newMessage.toMap());

  // Add the receiverId to the messagedUsers array in the current user's document
  await _fireStore.collection('users').doc(currentUserId).update({
    'messagedUsers': FieldValue.arrayUnion([receiverId]),
  });

  await _fireStore.collection('users').doc(receiverId).update({
    'messagedUsers': FieldValue.arrayUnion([currentUserId]),
  });


}

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _fireStore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:umarket/sell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_page.dart';

class Product extends StatefulWidget {
  final String itemName;
  final String itemPrice;
  final String itemImageUrl;
  final String listerName;
  final String sellerEmail;
  final String sellerUid; // Add sellerUid property
  final Timestamp timestamp;
  final String itemDescription;
  final String productID;
  final String cat;


  const Product({
    required this.itemName,
    required this.itemPrice,
    required this.itemImageUrl,
    required this.listerName,
    required this.sellerEmail,
    required this.sellerUid, // Add sellerUid parameter
    required this.timestamp,
    required this.itemDescription, 
    required this.productID,
    required this.cat,
  });

  @override
  _ProductState createState() => _ProductState();
}

class _ProductState extends State<Product> {
  String timeAgoFromTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final itemTime = timestamp.toDate();
    final difference = now.difference(itemTime);

    if (difference.inDays >= 1) {
      return 'Posted ${difference.inDays} day(s) ago';
    } else if (difference.inHours >= 1) {
      return 'Posted ${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes >= 1) {
      return 'Posted ${difference.inMinutes} minute(s) ago';
    } else {
      return 'Posted just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Product Details"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.itemImageUrl,
                    width: 330,
                    height: 330,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                widget.itemName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
              ),
              SizedBox(height: 8),
              Text(
                'Price: \$${widget.itemPrice}',
                style: TextStyle(fontSize: 24, color: Colors.black87, fontFamily: 'Times New Roman'),
              ),
              SizedBox(height: 8),
              Text(
                'Listed by: ${widget.listerName}',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontFamily: 'Times New Roman'),
              ),
              SizedBox(height: 8),
              Text(
                timeAgoFromTimestamp(widget.timestamp),
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontFamily: 'Times New Roman'),
              ),
              SizedBox(height: 12),
              Text(
                'Description:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman'),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Text(
                  widget.itemDescription,
                  style: TextStyle(fontSize: 18, color: Colors.black87, fontFamily: 'Times New Roman'),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
  onPressed: () {
    // Navigate to the ChatPage with the seller's UID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          receiverUserID: widget.sellerUid,
          userName: widget.listerName, // Use listerName as the user's name for the ChatPage
        ),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    primary: const Color.fromARGB(255, 4, 104, 186),
    onPrimary: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: EdgeInsets.symmetric(vertical: 16),
  ),
  icon: Icon(Icons.message),
  label: Text(
    'Message Seller',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
  ),
),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement send offer logic here
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.yellow[800],
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(Icons.send),
                label: Text(
                  'Send Offer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
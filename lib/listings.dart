import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:umarket/sell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyListings extends StatefulWidget {
  const MyListings({Key? key});

  @override
  State<MyListings> createState() => _MyListingsState();
}

class _MyListingsState extends State<MyListings> {
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

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

  void editPost(String itemName) {
    // Add functionality to edit the post
    // You can implement the logic here to edit the post
  }

  Future<void> deletePost(String itemName, String itemId) async {
    try {
      await FirebaseFirestore.instance.collection('marketplace').doc(itemId).delete();
      // Show a confirmation snackbar after the post is successfully deleted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post deleted successfully.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green, // Set the background color
          behavior: SnackBarBehavior.floating, // Make it float above the content
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          action: SnackBarAction(
            label: 'OK', // Add an action button to dismiss the snackbar
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Dismiss the snackbar
            },
          ),
        ),
      );
    } catch (e) {
      print('Error deleting post: $e');
      // Handle any error that occurred during the deletion process
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Listings"),
        automaticallyImplyLeading: false, // Remove the back button
        actions: [
          IconButton(
            onPressed: () {
              // Implement logout action here
              signUserOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SellProduct(),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: Text(
          "Sell",
          style: TextStyle(fontSize: 12),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('marketplace')
            .where('sellerEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email)
            .orderBy('timestamp', descending: true) // Add the orderBy clause
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<QueryDocumentSnapshot> items = snapshot.data!.docs;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemId = item.id; // Get the document ID of the item
                final itemName = item['name'];
                final itemPrice = item['price']; // Get the 'price' field value
                final itemImageUrl = item['image'];

                // Get the timestamp as a `Timestamp` object
                final Timestamp timestamp = item['timestamp'];

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Set the border color
                      width: 0.5, // Set the border width
                    ),
                    borderRadius: BorderRadius.circular(8), // Add rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          itemImageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 8),
                        Text(
                          itemName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Price: \$${itemPrice}', // Display the price with a dollar sign
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                        SizedBox(height: 8),
                        Text(
                          timeAgoFromTimestamp(timestamp),
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                editPost(itemName);
                              },
                              child: Text('Edit Post'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                onPrimary: Colors.white,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Confirm Deletion'),
                                      content: Text('Are you sure you want to delete this post?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            deletePost(itemName, itemId);
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text('Delete Post'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.red,
                                onPrimary: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching data'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

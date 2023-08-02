import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:umarket/product.dart';
import 'package:umarket/sell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Marketplace extends StatefulWidget {
  const Marketplace({Key? key}) : super(key: key);
  
  
  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  String searchText = '';
  List<QueryDocumentSnapshot>? filteredItems;
  // sign user out
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  void showMessageSnackbar(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You pressed on $itemName'),
        duration: Duration(seconds: 3),
      ),
    );
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

  void _viewProductDetails(
  String itemName,
  String itemPrice,
  String itemImageUrl,
  String listerName,
  String sellerEmail,
  String sellerUid, // Include the seller's UID as a parameter
  Timestamp timestamp,
  String itemDescription,
  String productID,
  String cat,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Product(
        itemName: itemName,
        itemPrice: itemPrice,
        itemImageUrl: itemImageUrl,
        listerName: listerName,
        sellerEmail: sellerEmail,
        sellerUid: sellerUid, // Pass the seller's UID to the Product widget
        timestamp: timestamp,
        itemDescription: itemDescription,
        productID: productID,
        cat: cat,
      ),
    ),
  );
}

  // Step 1: Add category options and selectedCategory variable here
  final List<String> categoryOptions = ['All', 'Trading Cards', 'Tickets', 'Plants', 'Other'];
  String selectedCategory = 'All';

  @override
Widget build(BuildContext context) {
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
  return Scaffold(
    appBar: AppBar(
      title: Text("Marketplace"),
      centerTitle: true, // Center the title in the app bar
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list),
          onSelected: (String category) {
            setState(() {
              selectedCategory = category;
            });
          },
          itemBuilder: (BuildContext context) {
            return categoryOptions.map((String category) {
              return PopupMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList();
          },
        ),
        IconButton(
          onPressed: () {
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
    body: Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchText = value.trim();
              });
            },
            decoration: InputDecoration(
              labelText: 'Search by item name',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('marketplace')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final List<QueryDocumentSnapshot> items = snapshot.data!.docs;

                // Filter out products that match the current user's UID
                final filteredItems = items
                    .where((item) => item['uid'] != currentUserUid)
                    .where((item) =>
                        selectedCategory == 'All' ||
                        item['category'] == selectedCategory)
                    .where((item) =>
                        searchText.isEmpty ||
                        item['name']
                            .toString()
                            .toLowerCase()
                            .contains(searchText.toLowerCase()))
                    .toList();

                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final itemName = item['name'];
                    final itemPrice = item['price'];
                    final itemImageUrl = item['image'];
                    final listerName = item['seller'];
                    final sellerEmail = item['sellerEmail'];
                    final itemDescription = item['description'];
                    final Timestamp timestamp = item['timestamp'];
                    final sellerUid = item['uid'];
                    final productID = item.id;
                    final cat = item['category'];

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Image.network(
                              itemImageUrl,
                              width: 100,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    itemName,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '\$$itemPrice',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Listed by: $listerName',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  ButtonBar(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _viewProductDetails(
                                            itemName,
                                            itemPrice,
                                            itemImageUrl,
                                            listerName,
                                            sellerEmail,
                                            sellerUid,
                                            timestamp,
                                            itemDescription,
                                            productID,
                                            cat,
                                          );
                                        },
                                        icon: Icon(Icons.message),
                                        label: Text('View product'),
                                        style: ElevatedButton.styleFrom(
                                          primary: Colors.blue,
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        cat, // Display the product category here
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    timeAgoFromTimestamp(timestamp),
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
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
        ),
      ],
    ),
  );
}

}

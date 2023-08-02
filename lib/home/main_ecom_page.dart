import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:umarket/marketplace.dart';
import 'package:umarket/messages.dart';
import 'package:umarket/listings.dart';
import 'package:umarket/home/user.dart';
import '../sell.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Sign user out
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _searchController = TextEditingController();
  bool _searchActivated = true; // Track whether the search field is activated
  bool _showErrorDialog = false;

  int _currentIndex = 0; // Track the current active page index

  // Function to delete the user if the email is not "@umich.edu"
  Future<void> deleteUserIfNotUmich() async {
  //final isUmichEmail = user.email!.endsWith("@umich.edu");
  final isUmichEmail = user.email!.endsWith("");
  if (!isUmichEmail) {
    try {
      await user.delete();
    } catch (e) {
      // Handle the error if needed
      print('Error deleting user: $e');
    }
  } else {
    try {
  // Check if the document already exists in Firestore
  final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final userSnapshot = await userRef.get();

  if (!userSnapshot.exists) {
    // If the document does not exist, create a new one
    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName,
      'messagedUsers': [], // Initialize an empty array for messagedUsers
    });
  }
} catch (e) {
  // Handle the error if needed
}
  }
}


  @override
  void initState() {
    super.initState();
    deleteUserIfNotUmich(); // Call the function to check and delete the user if needed
  }

  @override
  Widget build(BuildContext context) {
    // Check the user's email domain
    //final isUmichEmail = user.email!.endsWith("@umich.edu");
    final isUmichEmail = user.email!.endsWith("");
    if (!isUmichEmail && !_showErrorDialog) {
      // If it's not a umich.edu email and the error dialog is not already shown, show an error dialog
      _showErrorDialog = true;
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing the dialog by clicking outside
          builder: (context) => WillPopScope(
            // Disable the back button
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text('Invalid Email'),
              content: Text('You must log in with a @umich.edu-affiliated account.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    signUserOut();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        ).then((_) {
          // Set _showErrorDialog to false when the dialog is dismissed
          _showErrorDialog = false;
        });
      });
    }
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePageContent(
            user: user,
            searchController: _searchController,
            onSearch: () {
              // Toggle the search field activation and navigate to Marketplace
              setState(() {
                _searchActivated = true;
                _currentIndex = 1; // Set the index to the Marketplace tab
              });
            },
            onLogout: signUserOut,
            searchActivated: _searchActivated, // Pass the activation state to HomePageContent
          ),
          Marketplace(),
          Messages(), // Add the Messages page here
          MyListings(),
          Informations(),
          // Add other pages here
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to the "SellProduct" screen when the "Sell" button is pressed
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
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'User Information',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  final User user;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback onLogout;
  final bool searchActivated;

  HomePageContent({
    required this.user,
    required this.searchController,
    required this.onSearch,
    required this.onLogout,
    required this.searchActivated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40), // Add some padding at the top
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "UMarket",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    user.displayName ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.amber),
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 10),
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.search),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: searchActivated
                      ? TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Search for tickets...",
                            border: InputBorder.none,
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ),
              ElevatedButton(
                onPressed: onSearch,
                child: Text("Search"),
                style: ElevatedButton.styleFrom(
                  primary: Colors.white,
                  onPrimary: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text('Welcome to Home Page!'),
          ),
        ),
      ],
    );
  }
}

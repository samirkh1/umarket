import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class Informations extends StatefulWidget {
  const Informations({super.key});

  @override
  State<Informations> createState() => _InformationsState();
}

class _InformationsState extends State<Informations> {
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Information"),
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
    );
  }
}
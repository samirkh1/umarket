import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:umarket/services/auth_service.dart';
import 'auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UMarket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 145, 0)),
        useMaterial3: true,
      ),
      home: const Auth(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color darkishBlue = const Color(0xFF00274C);
  final Color darkerYellow = const Color(0xFFF7B50C);
  String wordwad = "";

  // Define the email and password controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void signUserIn() async {
    //show circular loading screen
    showDialog(
    context: context, 
    builder: (context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    );
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text, 
        password: passwordController.text,
        );
        Navigator.pop(context);
    } on FirebaseAuthException {
        Navigator.pop(context);
        wrongDetails(context);
    }

  
  }

  void wrongDetails(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Incorrect Email or Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Please check your email and password and try again.',
          style: TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Change the button color to red
            ),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: <TextSpan>[
              TextSpan(
                text: 'U',
                style: TextStyle(color: darkishBlue),
              ),
              TextSpan(
                text: 'Market',
                style: TextStyle(color: darkerYellow),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/outsourcing-peer-to-peer-marketplace-115631798176jvra8jwhi.png',
                        height: 300,
                        width: 300,
                      ),
                      const SizedBox(height: 20), // Add spacing between the image and the login fields
                      TextField(
                        controller: emailController, // Use the emailController for the email TextField
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10), // Add spacing between the login fields
                      TextField(
                        controller: passwordController, // Use the passwordController for the password TextField
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10), // Add spacing between the login fields and the login button
                      ElevatedButton(
                        onPressed: () {
                          signUserIn();
                        },
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => AuthService().signInWithGoogle(),
              icon: Image.asset(
                'assets/png-clipart-g-suite-pearl-river-middle-school-google-software-suite-email-sign-up-button-text-logo.png',
                height: 24,
                width: 24,
              ),
              label: const Text('Continue with Google'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: darkishBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'register.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api.dart';
import 'home.dart';
import 'officerhome.dart'; // Import officer home screen
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';
import 'dart:convert'; // Import for JSON decoding

bool isEmailValid(String email) {
  final checkValidEmail = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  return checkValidEmail.hasMatch(email);
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  String? errorText;

  @override
  void initState() {
    super.initState();
    checkUserLoggedIn();
  }


  Future<void> checkUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String userType = prefs.getString('usertype') ?? 'user';
    String name = prefs.getString('name') ?? 'Officer';
    String phoneNumber = prefs.getString('phone_number') ?? '0000000000';

    if (isLoggedIn) {
      if (userType == 'officer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OfficerHome(officerName: name, officerPhone: phoneNumber)), // Fixed
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      }
    }
  }

  /// **Save user data after login**
  Future<void> saveUserData(String email, String name, String phoneNumber, String userType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('name', name);
    await prefs.setString('phone_number', phoneNumber);
    await prefs.setString('usertype', userType);
    await prefs.setBool('isLoggedIn', true);
  }

  /// **Login Handler**
  void handleLogin() async {
    try {
      final response = await Api.loginUser(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          // Extract user details
          String email = responseData['data']['email'];
          String name = responseData['data']['name'];  // Fixed extraction
          String phoneNumber = responseData['data']['phone_number'];
          String userType = responseData['data']['usertype'] ?? 'user'; // Default to 'user' if not provided

          // Save user details
          await saveUserData(email, name, phoneNumber, userType);

          SnackBars.showSnackBarInfo(context, 'Login Successful');

          // **Navigate based on userType**
          if (userType == 'officer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OfficerHome(officerName: name,officerPhone :phoneNumber)), // Fixed
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          }
        } else {
          SnackBars.showSnackBarInfo(context, 'Login Failed');
        }
      } else {
        SnackBars.showSnackBarInfo(
          context,
          response.statusCode == 401 ? 'Invalid Credentials' : 'Error Logging in',
        );
      }
    } catch (e) {
      print("Error: $e");
      SnackBars.showSnackBarInfo(context, 'Something went wrong. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3D3D3D),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Color(0xFFFFFAEC),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                width: MediaQuery.of(context).size.width < 400
                    ? MediaQuery.of(context).size.width * 0.9
                    : 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Image.asset(
                        'lib/Images/s.png',
                        height: 100,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        "Login",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: usernameController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          setState(() {
                            errorText = isEmailValid(value) ? null : 'Please enter a valid email';
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.account_circle_outlined),
                          hintText: 'Email',
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          errorText: errorText,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        textInputAction: TextInputAction.done,
                        obscureText: true,
                        controller: passwordController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'Password',
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Login',
                            style: GoogleFonts.poppins(
                                fontSize: 20, color: Colors.white)),
                      ),
                    ),
                    Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        Text("Don't have an account?",
                            style: GoogleFonts.poppins(fontSize: 14)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Register()),
                            );
                          },
                          child: Text(
                            'Register',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

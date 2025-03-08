import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'api.dart';
import 'utils.dart';


class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorText; // Holds error text for email validation
  bool isLoading = false; // Tracks loading state

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D3D3D), // Background color
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: const Color(0xFFFFFAEC), // Card color
              child: Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.85,
                width: MediaQuery.of(context).size.width < 400
                    ? MediaQuery.of(context).size.width * 0.9
                    : 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Adding space for logo/image and form title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Image.asset(
                        'lib/Images/s.png', // Replace with your image asset
                        height: 80, // Adjust the height of the image
                        width: 80, // Adjust the width if needed
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        "Register",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    // Name Field
                    _buildTextField(
                      controller: nameController,
                      hintText: 'Name',
                      prefixIcon: Icons.account_circle_outlined,
                      inputType: TextInputType.name,
                    ),

                    // Email Field
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      inputType: TextInputType.emailAddress,
                      errorText: errorText,
                      onChanged: (value) {
                        setState(() {
                          errorText = isEmailValid(value) ? null : 'Invalid email';
                        });
                      },
                    ),

                    // Phone Field
                    _buildTextField(
                      controller: phoneController,
                      hintText: 'Phone Number',
                      prefixIcon: Icons.phone,
                      inputType: TextInputType.phone,
                    ),

                    // Password Field
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      inputType: TextInputType.visiblePassword,
                      obscureText: true,
                    ),

                    // Submit button
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, // Button color
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Register',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
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

  // Reusable method to build a text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required TextInputType inputType,
    String? errorText,
    bool obscureText = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 2,
            ),
          ),
          prefixIcon: Icon(prefixIcon),
          hintText: hintText,
        ),
      ),
    );
  }

  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
  }

  Future<void> _registerUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Api.registerUser(
        email: emailController.text,
        name: nameController.text,
        phone: phoneController.text,
        password: passwordController.text,
        usertype: 'user',
      );


      if (response.statusCode == 200) {
        if (context.mounted) {
          SnackBars.showSnackBarInfo(context, 'User registered successfully');

          Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
        }
      } else {
        SnackBars.showSnackBarInfo(context, response.statusCode==409 ? 'User already exists' : 'Failed to register user');
      }
    } catch (error) {
      SnackBars.showSnackBarInfo(context, error.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


}
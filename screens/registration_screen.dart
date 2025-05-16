import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'login_screen.dart';
import '/utils/my_utils.dart';


class RegistrationScreen extends StatefulWidget { 
  const RegistrationScreen({super.key});

  @override
  RegistrationFormState createState() => RegistrationFormState();
}

class RegistrationFormState extends State<RegistrationScreen> { 
  final _formKey = GlobalKey<FormState>(); 
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController tcKimlikController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isCofirmationPasswordVisible = false;
  bool isLoading = false;
  final String registerApiUrl = "$baseUrl/account/Register";

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return; 

    setState(() => isLoading = true);

    try {
      Uri uri = Uri.parse(registerApiUrl);
      http.Response response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
          "firstName": nameController.text,
          "lastName": lastNameController.text,
          "tcNumber": tcKimlikController.text,
        }),
      );

      // Handle redirect (307)
      if (response.statusCode == 307) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          uri = Uri.parse(redirectUrl);
          response = await http.post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": emailController.text,
              "password": passwordController.text,
              "firstName": nameController.text,
              "lastName": lastNameController.text,
              "tcNumber": tcKimlikController.text,
            }),
          );
        }
      }

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if(mounted) {
          showSafeSnackBar(context, "Registration Successful! Login to continue.", Colors.green);
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else if (response.statusCode == 400) {
        if(mounted){
          showSafeSnackBar(context, "Bad Request: ${response.body}", Colors.red);
        }
      } else if (response.statusCode == 500) {
        if(mounted){ 
          showSafeSnackBar(context, "Server Error: The user with the provided email already exists.", Colors.red);
        }
      } else {
        if(mounted){
          showSafeSnackBar(context, "Unexpected Error: ${response.statusCode} - ${response.body}", Colors.red);
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if(mounted){
        showSafeSnackBar(context, "Connection error: ${e.toString()}", Colors.red);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          title: const Text("Register"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, 
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: SingleChildScrollView( 
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16,),
      
                  TextFormField(
                    controller: lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your lastname";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16,),
      
                  TextFormField(
                    controller: tcKimlikController,
                    decoration: InputDecoration(
                      labelText: 'TC Kimlik',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length != 11) {
                        return 'TC should be 11 digits and number only';
                      }
                        else if (!RegExp(r'^[0-9]*$').hasMatch(value)) {
                        return 'Please enter a valid TC (numbers only)';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16,),
      
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16,),
      
                  TextFormField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(isPasswordVisible ? Icons.lock : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      else if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16,),
      
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !isCofirmationPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(isCofirmationPasswordVisible ? Icons.lock : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            isCofirmationPasswordVisible = !isCofirmationPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please re-enter your password';
                      }
                      else if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16,),
                  if (isLoading)
                  const CircularProgressIndicator(
                    color: Colors.black,
                  )
                  else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            registerUser();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5.0,
                          splashFactory: InkRipple.splashFactory,
                        ).copyWith(
                          overlayColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.deepOrange;
                              }
                              return null; 
                            },
                          ),
                        ),
                        child: const Text('Register'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5.0,
                          splashFactory: InkRipple.splashFactory,
                        ).copyWith(
                          overlayColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.deepOrange;
                              }
                              return null; 
                            },
                          ),
                        ),
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
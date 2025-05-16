import 'package:classifier_project2/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'registration_screen.dart';
import '/utils/my_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool isPasswordVisible = false;

  final String loginApiUrl = "$baseUrl/account/Login"; 
  
  
  Future<void> _profileInfo(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String profileUrl = "$baseUrl/user/Profile";

    try {
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Authorization': 'Bearer ${prefs.getString('jwt_token')}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final responseBody = response.body;
        final Map<String, dynamic> profileData = json.decode(responseBody);
        await prefs.setString('firstName', profileData['userInfo']['firstName']);
        await prefs.setString('role', profileData['userInfo']['role']['name']);

        // Handle nested address object
        final address = profileData['userInfo']['address'];
        if (address != null) {
          final formattedAddress = [
            address['street'],
            address['building'],
            address['appartment'],
            address['neighborhood'],
            address['postalCode'],
            address['city'],
            address['country']
          ].where((field) => field != null && field.isNotEmpty).join(', ');

          await prefs.setString('address', formattedAddress);
        } else {
          await prefs.setString('address', null!);
        }
      } else {
        if (mounted) {
          showSafeSnackBar(context, 'Error: ${response.statusCode} - ${response.body}', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error: $e', Colors.red);
      }
    }
  }

  Future<void> _login() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      Uri uri = Uri.parse(loginApiUrl);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }), 
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('authResponse') &&
            responseData['authResponse'].containsKey('idToken') &&
            responseData['authResponse']['idToken'] is String) {
          final String token = responseData['authResponse']['idToken'];
          final String refreshToken = responseData['authResponse']['refreshToken'];

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('refresh_token', refreshToken);
          await _profileInfo(context); 
           
          final String firstName = prefs.getString('firstName') ?? '';
          if (prefs.getString('address') == null) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen())
              );
              showSafeSnackBar(
                context,
                "Login Successful! Dear $firstName, please fill your address information.",
                Colors.brown,
              );
            }
          } else {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
              showSafeSnackBar(
                context,
              "Login Successful! Welcome back $firstName",
                Colors.green,
              );
            }
          }

        } else {
          if (mounted) {
            showSafeSnackBar(context, "Login failed: Token not found in response.", Colors.red);
          }
        }
      } else if (response.statusCode == 500) {
        if (mounted) {
          showSafeSnackBar(context, "Login failed! Invalid email or password.", Colors.red);
        }
      }
      else {
        if (mounted) {
          showSafeSnackBar(context, "Login failed. Status: ${response.statusCode}", Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
          showSafeSnackBar(context, "Connection error: No internet connection or Server down. Please check your network and try again.", Colors.red);
          print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove the back button
        title: const Text('Login'), 
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body:
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              TextFormField(
                  controller: _emailController,
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
                  controller: _passwordController,
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
    
              if (_isLoading)
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
                          _login();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(horizontal: 74.0, vertical: 8.0), 
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
                      child: const Text('Login'),
                    ),
                    TextButton(
                        onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegistrationScreen()),
                        );
                        },
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 8.0), 
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
                  ],
                ),
            ],
          ),
          ),
        ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async';
import 'screens/login_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/approved_screen.dart';
import 'screens/camera_upload_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/users_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/my_utils.dart';
import 'screens/base_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await _checkTokenAndStartApp();
}

Future<void> _checkTokenAndStartApp() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');
  final String? refreshToken = prefs.getString('refresh_token');

  if (token != null && _isTokenValid(token)) {
    final Duration timeUntilExpiry = JwtDecoder.getRemainingTime(token);

    Timer(timeUntilExpiry, () async {
      await _refreshToken(prefs, refreshToken);
    });

    runApp(MyApp(isLoggedIn: true)); 
  } else {
    runApp(MyApp(isLoggedIn: false));
  }
}

bool _isTokenValid(String token) {
  try {
    return !JwtDecoder.isExpired(token);
  } catch (e) {
    print('Error validating token: $e');
    return false;
  }
}

Future<void> _refreshToken(SharedPreferences prefs, String? refreshToken) async {
  if (refreshToken == null) return;

  try {
    Uri uri = Uri.parse('$baseUrl/account/refreshToken');
    final response = await http.post(
      uri,
      headers:{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final newToken = responseBody['idToken'];
      final newRefreshToken = responseBody['refreshToken'];
      final expiresIn = responseBody['expiresIn'];

      await prefs.setString('jwt_token', newToken);
      await prefs.setString('refresh_token', newRefreshToken);

      // Schedule the next refresh
      Duration timeUntilExpiry;
      if (JwtDecoder.tryDecode(newToken)?.containsKey('exp') == true) {
        timeUntilExpiry = JwtDecoder.getRemainingTime(newToken);
      } else {
        timeUntilExpiry = Duration(seconds: expiresIn);
      }
      Timer(timeUntilExpiry - Duration(seconds: 30), () async {
        await _refreshToken(prefs, newRefreshToken);
      });
    } else {
      print('Failed to refresh token: ${response.body}');
    }
  } catch (e) {
    print('Error refreshing token: $e');
  }
}


class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: isLoggedIn ? BaseScreen(child: const HomePage()) : LoginScreen(),
      routes: {
        '/home': (context) => BaseScreen(child: const HomePage()),
        '/login': (context) => LoginScreen(),
        '/registration': (context) => RegistrationScreen(),
        '/profile': (context) => BaseScreen(child: ProfileScreen()),
        '/pending': (context) => BaseScreen(child: const PendingScreen()),
        '/approved': (context) => BaseScreen(child: const ApprovedScreen()),
        '/camera': (context) => BaseScreen(child: const CameraUploadScreen()),
        '/users': (context) => BaseScreen(child: const UsersScreen()),
      },
    );
  }
}
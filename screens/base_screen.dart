import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaseScreen extends StatefulWidget {
  final Widget child;
  const BaseScreen({super.key, required this.child});

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  String? _role;
  late Map<int, String> _titles = {};

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final role = prefs.getString('role');

    setState(() {
      _isLoggedIn = token != null;
      _role = role;
      _initializeTitles();
    });
  }

  void _initializeTitles() {
    _titles = {
      0: 'Classifier App',
      1: 'Pending Images',
      2: _role == 'Worker' ? 'Camera' : 'Approved Images',
      3: _role == 'Admin' ? 'All Users' : 'Profile',
      if (_role == 'Admin') 4: 'Profile',
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentRoute = ModalRoute.of(this.context)?.settings.name;

    Map<String, int> routeMap = {
      '/home': 0,
      '/pending': 1,
      '/approved': 2,
      '/camera': 2,
      '/users': 3,
      '/profile': _role=='Admin' ? 4 : 3, 
    };

    setState(() {
      _selectedIndex = routeMap[currentRoute] ?? 0;
    });
  }


  List<BottomNavigationBarItem> _getBottomNavItems() {
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.pending), label: 'Pending'),
      BottomNavigationBarItem(
        icon: Icon(_role == 'Worker' ? Icons.camera_alt : Icons.check),
        label: _role == 'Worker' ? 'Camera' : 'Approved',
      ),
      if (_role == 'Admin')
        const BottomNavigationBarItem(icon: Icon(Icons.supervised_user_circle), label: 'Users'),
      BottomNavigationBarItem(
        icon: Icon(_isLoggedIn ? Icons.person : Icons.login),
        label: _isLoggedIn ? 'Profile' : 'Login',
      ),
    ];
  }

  void _onItemTapped(int index) {
    final routes = [
      '/home',
      '/pending',
      _role == 'Worker' ? '/camera' : '/approved',
      if (_role == 'Admin') '/users',
      _isLoggedIn ? '/profile' : '/login',
    ];

    if (index < routes.length) {
      Navigator.pushReplacementNamed(this.context, routes[index]);

      setState(() {
        // Ensure Profile has the correct index for Admin
        if (routes[index] == '/profile') {
          _selectedIndex = _role == 'Admin' ? 4 : 3;
        } else {
          _selectedIndex = index;
        }
      });
    }
 }


  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return Scaffold(
      appBar: currentRoute == '/profile'
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              title: Text(_titles[_selectedIndex] ?? ''),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        items: _getBottomNavItems(),
        currentIndex: _role== 'Admin' ? currentRoute == '/profile' ? 4 :_selectedIndex : _selectedIndex,
        unselectedItemColor: Colors.white,
        selectedItemColor: Colors.deepOrange,
        showSelectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
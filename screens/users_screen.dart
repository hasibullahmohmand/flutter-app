import 'package:flutter/material.dart';
import '../utils/my_utils.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/users.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}
class _UserScreenState extends State<UsersScreen> {
  List<User> _users = [];
  String? _email = "";
  bool _isLoading = true;

  @override
  void initState(){
    super.initState();
    _fetchUser();
    Future.delayed(Duration(seconds: 3), () {
    if(mounted){
      setState(() {
        _isLoading = false; 
      });}
    });
  }


  Future<void> _fetchUser() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    final String? email = prefs.getString('email');
    _email =email;
    Uri uri = Uri.parse('$baseUrl/user/getAllUsers');
    try{
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }
      );

      if(response.statusCode == 200 || response.statusCode == 201){
        if(mounted){
          setState(() {
            final List<dynamic> responseData = json.decode(response.body);
            print("Response Data: $responseData");
            _users = responseData.map((item) => User.fromJson(item)).toList();
          }); 
        }
      } else{
        showSafeSnackBar(context, "Failed to fetch users.", Colors.red);
        print("Error: ${response.statusCode} - ${response.body}");
      }
    }
    catch(e){
      print("Error fetching users: $e");
      if(mounted){
      showSafeSnackBar(context, "An error occurred while fetching users.", Colors.red);
      print(e);
      }
    }
  }

  Future<void> _assignRole(String userID, String? role) async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    Uri uri = Uri.parse('$baseUrl/account/assignRole');
    print("User ID: $userID");
    print("Role: $role");
    try{
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "userId": userID,
          "roleName": role,
        })
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        if(mounted){
          setState(() {
            showSafeSnackBar(context, "Role assigned successfully.", Colors.green);
          });
        }
      } else{
        showSafeSnackBar(context, "Failed to assign role.", Colors.red);
        print("Error: ${response.statusCode} - ${response.body}");
      }
    }
    catch (e){
      if(mounted){
        showSafeSnackBar(context, "An error occurred while assigning role.", Colors.red);
        print("Error assigning role: $e");
      }
    }
  } 


  void _showRoleAssignmentDialog(BuildContext context, User user) {
  String? _selectedRole = user.role; // Default role is the current user's role
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Assign Role to ${user.firstName} ${user.lastName}"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButton<String>(
              value: _selectedRole,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue; // Update the selected role
                });
              },
              items: ['Admin', 'Doctor', 'Worker'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            );
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("Save"),
            onPressed: () {
              // Assign the selected role to the user
              if (_selectedRole != null) {
                _assignRole(user.roleId, _selectedRole);
              }
              Navigator.of(context).pop();
              setState(() {}); // Update the UI
            },
          ),
        ],
      );
    },
  );
}




  @override
 Widget build(BuildContext context) {
  return Scaffold(
    body: _isLoading ? Center(
      child: CircularProgressIndicator(
        color: Colors.deepOrange,
      ),
    )
    : _users.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "No users found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
        : ListView.builder(
            itemCount: _users.length,
            itemBuilder: (BuildContext context, int index) {
              final user = _users[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  textColor: _email == user.email ? Colors.deepOrange : Colors.black,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      user.firstName.isNotEmpty
                          ? user.firstName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    "${user.firstName} ${user.lastName}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("Email: ${user.email}\nRole: ${user.role}"),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    _showRoleAssignmentDialog(context, user);
                  },
                ),
              );
            },
          ),
  );
}
}

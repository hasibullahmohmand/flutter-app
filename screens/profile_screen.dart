import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '/screens/login_screen.dart';
import 'dart:convert';
import '/utils/my_utils.dart';

final String profileUrl = "$baseUrl/user/Profile";
final String getAddressUrl = "$baseUrl/address/myaddress";
final String updateAddressUrl = "$baseUrl/address/update";
final String logoutUrl = "$baseUrl/account/Logout";

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  bool isLoggedOut = false;

  Map<String, String> userInfo = {
    'firstName': 'Loading...',
    'lastName': 'Loading...',
    'email': 'Loading...',
    'tcNumber': 'Loading...',
    'role': 'Loading...',
    'address': 'Loading...',
  };

  Map<String, String> addressInfo = {
    'country': '',
    'province': '',
    'city': '',
    'postalCode': '',
    'neighborhood': '',
    'street': '',
    'building': '',
    'appartment': '',
  };

  Future<void> _profileInfo(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Authorization': 'Bearer ${prefs.getString('jwt_token')}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final profileData = json.decode(response.body);
        await prefs.setString('firstName', profileData['userInfo']['firstName']);
        await prefs.setString('lastName', profileData['userInfo']['lastName']);
        await prefs.setString('email', profileData['userInfo']['email']);
        await prefs.setString('tcNumber', profileData['userInfo']['tcNumber']);
        await prefs.setString('role', profileData['userInfo']['role']['name']);

        // Handle nested address object
        final address = profileData['userInfo']['address'];
        if (address != null) {
          final formattedAddress = [
            address['appartment'],
            address['building'],
            address['street'],
            address['neighborhood'],
            address['postalCode'],
            address['city'],
            address['province'],
            address['country']
          ].where((field) => field != null && field.isNotEmpty).join(', ');

          await prefs.setString('address', formattedAddress);
        } else {
          await prefs.setString('address', null!);
        }

        if (mounted) { // Ensure widget is still mounted
          setState(() {
            userInfo['firstName'] = profileData['userInfo']['firstName'];
            userInfo['lastName'] = profileData['userInfo']['lastName'];
            userInfo['email'] = profileData['userInfo']['email'];
            userInfo['tcNumber'] = profileData['userInfo']['tcNumber'];
            userInfo['role'] = profileData['userInfo']['role']['name'];
            userInfo['address'] = prefs.getString('address')!;

            // Make address fields visible and mandatory if address is null
            isAddressEditable = userInfo['address']?.isEmpty ?? true;
          });
        }
      } else {
        if(mounted){
        showSafeSnackBar(context, 'Failed to fetch profile info. Status: ${response.statusCode}', Colors.red);}
      }
    } catch (e) {
      if(mounted){
      showSafeSnackBar(context, 'An error occurred while fetching profile info.', Colors.red);}
    }
  }

  bool isAddressEditable = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _profileInfo(context).then((_) => _fetchUserInfo());
  }

  Future<void> _fetchUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) { // Ensure widget is still mounted
      setState(() {
        userInfo['firstName'] = prefs.getString('firstName') ?? 'N/A';
        userInfo['lastName'] = prefs.getString('lastName') ?? 'N/A';
        userInfo['email'] = prefs.getString('email') ?? 'N/A';
        userInfo['tcNumber'] = prefs.getString('tcNumber') ?? 'N/A';
        userInfo['role'] = prefs.getString('role') ?? 'N/A';
        userInfo['address'] = prefs.getString('address') ?? 'N/A';
      });
    }

    if (userInfo['address'] == 'N/A') {
      if (mounted) { // Ensure widget is still mounted
        setState(() {
          isAddressEditable = true;
        });
      }
    } else {
      await _fetchAddressInfo();
    }
  }

  Future<void> _fetchAddressInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    try {
      final response = await http.get(
        Uri.parse(getAddressUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (mounted) {
          setState(() {
            addressInfo = {
              'country': responseBody['country']!,
              'province': responseBody['province']!,
              'city': responseBody['city']!,
              'postalCode': responseBody['postalCode']!,
              'neighborhood': responseBody['neighborhood']!,
              'street': responseBody['street']!,
              'building': responseBody['building']!,
              'appartment': responseBody['appartment']!,
            };

            // Combine address fields into a single string for userInfo['address']
            userInfo['address'] = [
              addressInfo['appartment'],
              addressInfo['building'],
              addressInfo['street'],
              addressInfo['neighborhood'],
              addressInfo['postalCode'],
              addressInfo['city'],
              addressInfo['province'],
              addressInfo['country']
            ].where((field) => field != null && field.isNotEmpty).join(', ');
            prefs.setString('address', userInfo['address']!);
          });
        }
      } else {
        if(mounted){
          showSafeSnackBar(context, 'Failed to fetch address info. Status: ${response.statusCode}', Colors.red);
        }
      }
    } catch (e) {
      if(mounted){
        showSafeSnackBar(context, 'An error occurred while fetching address info.', Colors.red);
      }
    }
  }

  Future<void> _updateAddress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    if (mounted) {
      setState(() {
        isSubmitting = true;
      });
    }
    try {
      final response = await http.post(
        Uri.parse(updateAddressUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(addressInfo),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['result'] != null) { 
          if(mounted){
            showSafeSnackBar(context, 'Address updated successfully!', Colors.green);
          }
          await _fetchAddressInfo(); 
        } else {
          if(mounted){
            showSafeSnackBar(context, 'Failed to update address. Unexpected server response.', Colors.red);
          }
        }
      } else {
        if(mounted){
          showSafeSnackBar(context, 'Failed to update address. Status: ${response.statusCode}', Colors.red);
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitAddress() async {
    // Check if all required fields are filled
    bool isValid = addressInfo.values.every((value) => value.isNotEmpty);

    if (!isValid) {
      if(mounted){
      showSafeSnackBar(context, 'Please fill in all address fields before submitting.', Colors.red);
      }
      return;
    }

    // Proceed to update the address if validation passes
    await _updateAddress();
    if (mounted) {
      setState(() {
        isAddressEditable = false;
      });
    }
    Navigator.pushReplacementNamed(context, '/profile');
  }

  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      if(mounted){
      showSafeSnackBar(context, 'No token found. Please log in again.', Colors.red);
      }
      return;
    }

    try {
      setState(() {
        isLoggedOut = true;
      });
      
      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }
      );

      if (response.statusCode == 200) {
        await prefs.clear();
        if(mounted){
        showSafeSnackBar(context, "Logged out successfully!", Colors.green);
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      } else {
        if(mounted){
        showSafeSnackBar(context, "Logout failed. Status: ${response.statusCode}", Colors.red);
        }
      }
    } catch (e) {
      if(mounted){
      showSafeSnackBar(context, 'An error occurred while logging out.', Colors.red);
      }
    }
  }


  Widget _buildInfoField(String label, String value, bool editable, Function(String)? onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: editable && value.isEmpty ? Colors.red : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: editable
                ? TextFormField(
                    onChanged: onChanged,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      errorText: value.isEmpty ? 'This field is required' : null,
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 44.0, vertical: 8.0),
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
                  child: Text('Logout'),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if(isAddressEditable)
                  Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade300,
                            child: Icon(
                              Icons.map,
                              size: 50,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(left: 16)),
                          Text(
                            'Address Information',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Please compelete your address before continuing!!!',
                        style: TextStyle(
                          color: Colors.red,
                        ),),
                      SizedBox(height: 10)
                    ],
                  ),
                  if (isAddressEditable) // Show address fields if editable
                    Form(
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          _buildInfoField('Country:', addressInfo['country']!, true, (value) {
                            setState(() {
                              addressInfo['country'] = value;
                            });
                          }),
                          SizedBox(height: 10),
                          _buildInfoField('Province:', addressInfo['province']!, true, (value) {
                            setState(() {
                              addressInfo['province'] = value;
                            });
                          }),
                          SizedBox(height: 10),
                          _buildInfoField('City:', addressInfo['city']!, true, (value) {
                            setState(() {
                              addressInfo['city'] = value;
                            });
                          }),
                          SizedBox(height: 10),
                          _buildInfoField('Postal Code:', addressInfo['postalCode']!, true, (value) {
                            setState(() {
                              addressInfo['postalCode'] = value;
                            });
                          }),
                          SizedBox(height: 10),
                          _buildInfoField('Neighborhood:', addressInfo['neighborhood']!, true, (value) {
                            setState(() {
                              addressInfo['neighborhood'] = value;
                            });
                          }),
                          SizedBox(height: 10),
                          _buildInfoField('Street:', addressInfo['street']!, true, (value) {
                            setState(() {
                              addressInfo['street'] = value;
                            });
                          }),
                          SizedBox(height: 10),
                          _buildInfoField('Building:', addressInfo['building']!, true, (value) {
                            setState(() {
                              addressInfo['building'] = value;
                            });
                          }),
                          SizedBox(height: 10),
                          _buildInfoField('Appartment:', addressInfo['appartment']!, true, (value) {
                            setState(() {
                              addressInfo['appartment'] = value;
                            });
                          }),
                          SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 44.0, vertical: 8.0),
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
                            onPressed: _submitAddress,
                            child:Text('Submit'),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Padding(padding: EdgeInsets.only(left: 16)),
                      Text(
                        'User Information',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildInfoField('First Name:', userInfo['firstName']!, false, null),
                  SizedBox(height: 10),
                  _buildInfoField('Last Name:', userInfo['lastName']!, false, null),
                  SizedBox(height: 10),
                  _buildInfoField('Email:', userInfo['email']!, false, null),
                  SizedBox(height: 10),
                  _buildInfoField('TC Number:', userInfo['tcNumber']!, false, null),
                  SizedBox(height: 10),
                  _buildInfoField('Account type:', userInfo['role']!, false, null),
                  SizedBox(height: 10),
                  _buildInfoField('Address:', userInfo['address']!, false, null),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
         if (isLoggedOut || isSubmitting)
        Positioned.fill(
          child: ModalBarrier(
            color: Colors.black.withOpacity(0.5),
            dismissible: false,
          ),
        ),
      
      if (isLoggedOut || isSubmitting)
        const Positioned.fill(
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
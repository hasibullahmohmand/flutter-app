import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/my_utils.dart';
import '../models/Evaluated.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApprovedScreen extends StatefulWidget {
  const ApprovedScreen({super.key});

  @override
  _ApprovedScreenState createState() => _ApprovedScreenState();
}

class _ApprovedScreenState extends State<ApprovedScreen> {
  List<Evaluated> _approvedImages = [];
  bool _isLoading = true;
  Evaluated? _selectedEvaluated;

  @override
  void initState() {
    super.initState();
    _fetchApprovedImages();
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchApprovedImages() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      final String? role = prefs.getString('role');
      print("Role: $role");

      Uri uri = role == "Admin" ? Uri.parse("$baseUrl/media/evaluatedMedias"): 
      Uri.parse('$baseUrl/media/myEvaluatedMedias');

      try {
        final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print("response sent");
      print(response.statusCode);
          

       if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            final List<dynamic> responseData = json.decode(response.body);
            _approvedImages = responseData.map((item) => Evaluated.fromJson(item)).toList();

            print(_approvedImages);
          });
        }
      } else {
        showSafeSnackBar(context, "Failed to fetch pending images.", Colors.red);
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, "Network error: Unable to connect. $e", Colors.red);
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? Center(
      child: CircularProgressIndicator(
        color: Colors.deepOrange,
      ),
    )
    :_approvedImages.isEmpty ? 
      Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "No media found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
      : Stack(
    children: [
      // Grid of evaluated images
      GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _approvedImages.length, // List<Evaluated>
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final Evaluated item = _approvedImages[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedEvaluated = item;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: item.healthStatus == 1 ? Colors.green : Colors.red,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),

      // Fullscreen viewer for selected image
      if (_selectedEvaluated != null)
        GestureDetector(
          onTap: () => setState(() => _selectedEvaluated = null),
          child: Container(
            color: Colors.black.withOpacity(0.9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Image.network(
                      _selectedEvaluated!.imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text("Uploaded At: ${_selectedEvaluated!.uploadedAt}", style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("Evaluated At: ${_selectedEvaluated!.evaluatedAt}", style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        "Health Status: ${_selectedEvaluated!.healthStatus == 1 ? 'Healthy' : 'Not Healthy'}",
                        style: TextStyle(
                          color: _selectedEvaluated!.healthStatus == 1 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
    ],
  );
}
}
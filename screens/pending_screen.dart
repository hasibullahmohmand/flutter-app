import 'package:classifier_project2/models/pending.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/utils/my_utils.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  _PendingScreenState createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  List<Pending> _pendingImages = [];
  String? _selectedImage;
  String? _selectedImageId;
  bool _isWorker = false;
  bool _isLoading = true;
  bool _isEvaluating = false;

  TextEditingController ?_commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPendingImages();
    Future.delayed(Duration(seconds: 3), () {
    if(mounted){
      setState(() {
        _isLoading = false; 
      });}
    });
  }


  Future<void> _fetchPendingImages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    final String? role = prefs.getString('role');
    print(role);
    try {
      setState(() {
        _isWorker = role == 'Worker' ? true : false;
      });
      Uri uri = role == 'Worker' ? Uri.parse('$baseUrl/media/myPendingMedias'):
      Uri.parse('$baseUrl/media/pendingMedias');
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
            _pendingImages = responseData.map((item) => Pending.fromJson(item)).toList();
            print(_pendingImages);
          });
        }
      } else {
        showSafeSnackBar(context, "Failed to fetch pending images.", Colors.red);
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, "Network error: Unable to connect. $e", Colors.red);
      }
    }
  }

  Future<void> _deleteImage(String? id) async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    setState(() {
      _isEvaluating = true;
    });
    try{
      Uri uri = Uri.parse('$baseUrl/media/delete/?mediaId=$id');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'id': '$id'
        }
      );
      setState(() {
        _isEvaluating = false;
      });
      if(response.statusCode == 200){
        if(mounted){
        showSafeSnackBar(context, 'Image deleted successfully!', Colors.green);
        await _fetchPendingImages();
        }
      }
      else{
        if(mounted){
        showSafeSnackBar(context, 'Server error! Image not deleted.', Colors.red);
        print(response.statusCode);
        print(response.body);
        
        print(_pendingImages);
        }
      }

    }
    catch(e){
      if(mounted){
      showSafeSnackBar(context, 'Error! $e. Image not deleted.', Colors.red);
      print(e);
      }
    }
  }

  Future<void> _evaluateImage(String? id, int healthStatus, String? description) async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    Uri uri = Uri.parse('$baseUrl/media/evaluationOfMedia/?mediaId=$id');
    setState(() {
      _isEvaluating = true;
    });
    try{
      final response = await http.post(
        uri,
        headers:{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
        "healthStatus": healthStatus,  
        "description": description
        })
      );
      setState(() {
        _isEvaluating = false;
      });
      if (response.statusCode == 200){
        if(mounted){
          showSafeSnackBar(context, 'Image Evaluated successfully!', Colors.green);
          await _fetchPendingImages();
        }
      }
      else{
        if(mounted){
          showSafeSnackBar(context, "Server error! Couldn't evaluate the image.", Colors.red);
        }
      }
    }
    catch(e){
      print(e);
       if(mounted){
          showSafeSnackBar(context, "Error! $e Couldn't evaluate the image.", Colors.red);
        }
    }
  }

  Future<void> showDialogBox(String status, int healthStatus){
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: status == 'evaluate' ? Text('Confirm Evaluation') : Text('Confirm Deletion'),
          content: status == 'evaluate' ? healthStatus== 1 ? 
          Text('Are you sure you want to $status this image as 1?') : 
          Text('Are you sure you want to $status this image as 0?') :
          Text('Are you sure you want to $status this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                if (status == 'evaluate'){
                _evaluateImage(_selectedImageId, healthStatus, _commentController?.text);
                }
                else{
                  _deleteImage(_selectedImageId);
                }
                Navigator.pop(context); 
                setState(() {
                  _selectedImage = null;
                  _selectedImageId = null;
                  _commentController?.clear();
                });
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return 
    _isLoading ? Center(
          child: CircularProgressIndicator(
            color:Colors.deepOrange
            ),)
    :_pendingImages.isEmpty ? 
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No media found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      )
     :Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _pendingImages.length,
              itemBuilder: (context, index) {
                final imageUrl = _pendingImages[index].imageUrl;
                final imageId = _pendingImages[index].id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedImage = imageUrl;
                      _selectedImageId = imageId;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.grey),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedImage != null)
            GestureDetector(
              onTap: () => setState(() {
                _selectedImage = null;
                _selectedImageId = null;
                _commentController?.clear();
              } ),
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.network(
                          _selectedImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if(!_isWorker)Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if(!_isWorker)IconButton(
                          onPressed: () {
                            print(1);
                            showDialogBox('evaluate', 1);
                          },
                          icon: const Icon(Icons.check, color: Colors.white),
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
                        ),
                        if(!_isWorker)const SizedBox(width: 10),
                        if(!_isWorker)IconButton(
                          onPressed: () {
                            print(0);
                            showDialogBox('evaluate', 0);
                          },
                          icon: const Icon(Icons.close, color: Colors.white,),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
                                  return Colors.green;
                                }
                                return null; 
                              },
                            ),
                          ),
                        ),
                        if(!_isWorker)const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            print(-1);
                            showDialogBox("delete", -1);
                          },
                          icon: const Icon(Icons.delete_forever, color: Colors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white, 
                            padding: _isWorker?EdgeInsets.symmetric(horizontal: 150.0, vertical: 8.0) : EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0), 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0), 
                            ),
                            elevation: 5.0, 
                            splashFactory: InkRipple.splashFactory,
                          ).copyWith(
                            overlayColor: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return Colors.green;
                                }
                                return null; 
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

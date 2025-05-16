import 'package:classifier_project2/utils/my_utils.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _predict(BuildContext context) async {
    showSafeSnackBar(context, "This option will be available soon...", Colors.brown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: SweepGradient(
            colors: [Colors.black, Colors.grey, Colors.black],
            
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to the Classifier App!",
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              Text(
                "Press the predict button to start.",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () => _predict(context), // Wrap in an anonymous function
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
                child: Text("Predict"))
            ],
          ),
          
        ),
      ),
    );
  }
}
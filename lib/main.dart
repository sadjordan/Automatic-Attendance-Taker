import 'package:flutter/material.dart';
import 'package:tragedy/pages/ijustwanttobehappy.dart';
import 'package:tragedy/pages/maybeishouldstopthisobsessionwithsadness.dart';
import 'package:tragedy/pages/thetragedyofourtimes.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:camera/camera.dart';

Future<void> main() async {
  runApp(const SadApp());
}

class SadApp extends StatefulWidget {
  const SadApp({super.key});

  @override
  State<SadApp> createState() => _SadAppState();
}

class _SadAppState extends State<SadApp> {
  int currentPage = 0;

  final List<Widget> Pages = [
    const Camera(),
    const Home(),
    const Profile()
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(0, 224, 74, 74),
          title: const Text('This is a sad app'),
        ),
        body: Pages[currentPage],
        floatingActionButton: FloatingActionButton(
          child: Text('Sad'),
          onPressed: () {
            print('Sadness');}
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          currentIndex: currentPage,
          onTap: (value) {
            setState(() {
              currentPage = value;
            });
          },
          items: const[
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Camera',
              backgroundColor: Colors.red),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              backgroundColor: Colors.blue),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
              backgroundColor: Colors.green),
          ]
        ),
      ),
    );
  }
}
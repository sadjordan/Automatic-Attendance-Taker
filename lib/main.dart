import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tragedy/pages/maybeishouldstopthisobsessionwithsadness.dart';
import 'package:tragedy/pages/thetragedyofourtimes.dart';
import 'package:tragedy/dialogs/settings_dialog.dart';
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
    // const Home(link: null),
    const Profile()
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Add localization support
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
      ],
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(0, 224, 74, 74),
          title: const Text('This is a sad app'),
        ),
        body: Pages[currentPage],
        floatingActionButton: Builder(
          builder: (BuildContext context) {
            return FloatingActionButton(
              child: const Icon(Icons.settings),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return const SettingsDialog();
                  },
                );
              }
            );
          }
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
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.home),
            //   label: 'Home',
            //   backgroundColor: Colors.blue),
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
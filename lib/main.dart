import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tragedy/pages/maybeishouldstopthisobsessionwithsadness.dart';
import 'package:tragedy/pages/thetragedyofourtimes.dart';
import 'package:tragedy/dialogs/settings_dialog.dart';
import 'package:tragedy/services/credential_manager.dart';
import 'package:tragedy/dialogs/database_helper_dialog.dart';
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
  final CredentialManager _credentialManager = CredentialManager();
  bool _databaseInitialized = false;

  final List<Widget> Pages = [
    const Camera(),
    // const Home(link: null),
    const Profile()
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }
  
  Future<void> _initializeDatabase() async {
    try {
      // This will trigger database initialization without causing recreation
      await _credentialManager.checkDatabaseIntegrity();
      setState(() {
        _databaseInitialized = true;
      });
    } catch (e) {
      print('Error initializing database: $e');
      // We'll handle this in the UI
    }
  }

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
          actions: [
            // Database status indicator
            if (!_databaseInitialized)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: Icon(Icons.storage),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DatabaseHelperDialog(),
                );
              },
              tooltip: 'Database Tools',
            ),
          ],
        ),
        body: !_databaseInitialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing database...'),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => DatabaseHelperDialog(),
                      );
                    },
                    child: Text('Database Tools'),
                  ),
                ],
              )
            )
          : Pages[currentPage],
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
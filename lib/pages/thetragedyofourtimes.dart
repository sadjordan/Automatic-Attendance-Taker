import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController student_idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // var databaseFactory = databaseFactoryFfi;

  void db_stuff() async {
    // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    //   sqfliteFfiInit();
    //   databaseFactory = databaseFactoryFfi;
    // } 

    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'profile.db');

    Database database = await openDatabase(path, version: 1,
    onCreate: (Database db, int version) async {
      await db.execute(
          '''CREATE TABLE if not exists Profile (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT, 
          student_ID TEXT NOT NULL, 
          password TEXT NOT NULL''');
      }
    );
  }

  void db_insert(String name, String student_id, String password) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'profile.db');
    Database database = await openDatabase(path);
    
    List<Map> list = await database.rawQuery('SELECT * FROM Profile');

    if (list.isNotEmpty) {
      await database.transaction((txn) async {
        await txn.rawInsert(
          '''
          INSERT INTO Test(name, student_ID, password)
          VALUES(?, ?, ?)
          ''',
          [name, student_id, password]
        );
      }
    );
    }
    List<Map<String, dynamic>> rows = await database.rawQuery('SELECT * FROM Profile');

  // Show the data in a message box
  showDialog(
    context: this.context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Database Records'),
        content: SingleChildScrollView(
          child: ListBody(
            children: rows.map((row) {
              return Text(
                'ID: ${row['id']}, Name: ${row['name']}, Student ID: ${row['student_ID']}, Password: ${row['password']}',
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(this.context).pop();
            },
          ),
        ],
      );
    },
  );
  }
  

  @override
  Widget build(BuildContext context) {
    

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Name: ',
                  style: TextStyle(fontSize: 18),
                ),
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      prefix: Text('Optional: '),
                    ),
                  ))
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Student ID: ',
                  style: TextStyle(fontSize: 18),
                ),
                Expanded(
                  child: TextFormField(
                    controller: student_idController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Field cannot be empty';
                      }
                    },
                  ))
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Password: ',
                    style: TextStyle(fontSize: 18),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Field cannot be empty';
                        }
                      },
                    )
                  )
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          db_stuff();

                          String name = nameController.text;
                          String student_id = student_idController.text;
                          String password = passwordController.text;

                          db_insert(name, student_id, password);
                        }
                      } ,
                      child: Text("Save"))
                  )
                ],
              )
          ],
        ),
      ));
  }
}
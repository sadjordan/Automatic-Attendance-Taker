import 'package:flutter/material.dart';
import '../services/credential_manager.dart';
import '../dialogs/database_helper_dialog.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _obscurePassword = true;
  bool _isDatabaseReady = false;
  String _databaseStatus = 'Checking database...';
  final _formKey = GlobalKey<FormState>();
  final CredentialManager _credentialManager = CredentialManager();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController student_idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _checkDatabaseReady();
  }
  
  // Check if database is ready to use
  Future<void> _checkDatabaseReady() async {
    try {
      // Use a simple query to check database availability
      final result = await _credentialManager.checkDatabaseIntegrity();
      setState(() {
        _isDatabaseReady = result['integrity_ok'] == true;
        _databaseStatus = _isDatabaseReady 
            ? 'Database ready'
            : 'Database issue detected. Please check database tools.';
      });
    } catch (e) {
      setState(() {
        _isDatabaseReady = false;
        _databaseStatus = 'Database error: $e';
      });
    }
  }

  void saveCredentials() async {
    String name = nameController.text;
    String student_id = student_idController.text;
    String password = passwordController.text;
    
    await _credentialManager.saveCredentials(name, student_id, password);
    
    if (!mounted) return;
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credentials saved successfully!')),
    );
    
    // Clear the form
    nameController.clear();
    student_idController.clear();
    passwordController.clear();
  }
  
  // Show delete confirmation dialog
  void _showDeleteConfirmation(int id, BuildContext parentContext) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Credential'),
          content: const Text('Are you sure you want to delete this entry?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () async {
                await _credentialManager.deleteCredential(id);
                if (!mounted) return;
                
                // Close delete confirmation dialog
                Navigator.of(dialogContext).pop();
                // Close entries dialog and reopen to refresh
                Navigator.of(parentContext).pop();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Entry deleted successfully')),
                );
                
                // Refresh the entries list
                showAllEntries();
              },
            ),
          ],
        );
      },
    );
  }
  
  // Show edit dialog with form
  void _showEditDialog(Map<String, dynamic> entry, BuildContext parentContext) {
    final TextEditingController nameEditController = TextEditingController(text: entry['name']);
    final TextEditingController studentIdEditController = TextEditingController(text: entry['student_ID']);
    final TextEditingController passwordEditController = TextEditingController(text: entry['password']);
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Credential'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameEditController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: studentIdEditController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Student ID cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordEditController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await _credentialManager.updateCredential(
                        entry['id'],
                        nameEditController.text,
                        studentIdEditController.text,
                        passwordEditController.text
                      );
                      
                      if (!mounted) return;
                      
                      // Close edit dialog
                      Navigator.of(dialogContext).pop();
                      // Close entries dialog and reopen to refresh
                      Navigator.of(parentContext).pop();
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Entry updated successfully')),
                      );
                      
                      // Refresh the entries list
                      showAllEntries();
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  void showAllEntries() async {
    List<Map<String, dynamic>> entries = await _credentialManager.getAllCredentials();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Stored Credentials'),
          content: SizedBox(
            width: double.maxFinite,
            child: entries.isEmpty 
              ? const Center(child: Text('No credentials stored yet.'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Student ID: ${entries[index]['student_ID']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: ${entries[index]['name'] ?? 'Not provided'}'),
                            Text('Password: ${entries[index]['password']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditDialog(entries[index], dialogContext);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(entries[index]['id'], dialogContext);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show database status indicator if there are issues
    if (!_isDatabaseReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Database Issue Detected',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _databaseStatus,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DatabaseHelperDialog(),
                );
              },
              child: Text('Open Database Tools'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: _checkDatabaseReady,
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    // Regular UI when database is ready
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
                      return null;
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
                        return null;
                      },
                    )
                  )
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          saveCredentials();
                        }
                      },
                      child: const Text("Save")
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: ElevatedButton(
                      onPressed: showAllEntries,
                      child: const Text("View All Entries")
                    ),
                  )
                ],
              )
          ],
        ),
      ));
  }
}
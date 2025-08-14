import 'package:flutter/material.dart';
import '../services/credential_manager.dart';

class DatabaseHelperDialog extends StatefulWidget {
  const DatabaseHelperDialog({Key? key}) : super(key: key);

  @override
  State<DatabaseHelperDialog> createState() => _DatabaseHelperDialogState();
}

class _DatabaseHelperDialogState extends State<DatabaseHelperDialog> {
  final CredentialManager _credentialManager = CredentialManager();
  bool _isChecking = false;
  Map<String, dynamic> _integrityResults = {};
  String _statusMessage = '';
  bool _isRestoring = false;
  String? _backupPath;

  @override
  void initState() {
    super.initState();
    _checkDatabaseIntegrity();
  }

  Future<void> _checkDatabaseIntegrity() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking database integrity...';
    });

    try {
      final results = await _credentialManager.checkDatabaseIntegrity();
      
      setState(() {
        _integrityResults = results;
        _isChecking = false;
        _statusMessage = results['integrity_ok'] == true 
            ? 'Database integrity check passed.'
            : 'Database integrity check failed. Consider restoring from backup.';
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Error checking database integrity: $e';
      });
    }
  }

  Future<void> _backupDatabase() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Creating database backup...';
    });

    try {
      final backupPath = await _credentialManager.backupDatabase();
      
      setState(() {
        _backupPath = backupPath;
        _isChecking = false;
        _statusMessage = backupPath != null 
            ? 'Database backup created successfully.'
            : 'Failed to create database backup.';
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Error creating database backup: $e';
      });
    }
  }

  Future<void> _restoreDatabase() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore Database?'),
        content: Text('This will restore the database from the most recent backup. '
            'Any changes made since the last backup will be lost.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: Text('Restore'),
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
      _statusMessage = 'Restoring database from backup...';
    });

    try {
      final success = await _credentialManager.restoreFromBackup();
      
      setState(() {
        _isRestoring = false;
        _statusMessage = success 
            ? 'Database restored successfully. Please restart the app.'
            : 'Failed to restore database: No backups found.';
      });

      // If successful, re-check integrity
      if (success) {
        await Future.delayed(Duration(seconds: 1));
        _checkDatabaseIntegrity();
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
        _statusMessage = 'Error restoring database: $e';
      });
    }
  }

  Future<void> _forceRecreateDatabase() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recreate Database?'),
        content: Text('WARNING: This will delete all data and recreate the database. '
            'This action cannot be undone unless you have a backup.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: Text('Recreate'),
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isChecking = true;
      _statusMessage = 'Recreating database...';
    });

    try {
      final success = await _credentialManager.forceRecreateDatabase();
      
      setState(() {
        _isChecking = false;
        _statusMessage = success 
            ? 'Database recreated successfully. Please restart the app.'
            : 'Failed to recreate database.';
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Error recreating database: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Database Maintenance'),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Message
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              width: double.infinity,
              child: Text(_statusMessage),
            ),
            SizedBox(height: 16),
            
            // Integrity results
            if (_isChecking || _isRestoring)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(_isRestoring ? 'Restoring...' : 'Checking...'),
                  ],
                ),
              )
            else if (_integrityResults.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Integrity Status: ${_integrityResults['integrity_ok'] == true ? 'OK' : 'FAILED'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _integrityResults['integrity_ok'] == true 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      Text('Database exists: ${_integrityResults['database_exists'] == true ? 'Yes' : 'No'}'),
                      SizedBox(height: 8),
                      
                      if (_integrityResults['error'] != null)
                        Text('Error: ${_integrityResults['error']}', 
                          style: TextStyle(color: Colors.red)),
                      
                      if (_integrityResults['tables'] != null) ...[
                        SizedBox(height: 16),
                        Text('Tables:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._integrityResults['tables'].map<Widget>((table) => 
                          Padding(
                            padding: EdgeInsets.only(left: 16, top: 4),
                            child: Text(table),
                          )
                        ).toList(),
                      ],
                      
                      if (_integrityResults['record_counts'] != null) ...[
                        SizedBox(height: 16),
                        Text('Record Counts:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...(_integrityResults['record_counts'] as Map<String, dynamic>)
                          .entries
                          .map<Widget>((entry) => 
                            Padding(
                              padding: EdgeInsets.only(left: 16, top: 4),
                              child: Text('${entry.key}: ${entry.value} records'),
                            )
                          ).toList(),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        // Action buttons
        TextButton(
          child: Text('Refresh'),
          onPressed: _isChecking || _isRestoring ? null : _checkDatabaseIntegrity,
        ),
        TextButton(
          child: Text('Backup'),
          onPressed: _isChecking || _isRestoring ? null : _backupDatabase,
        ),
        TextButton(
          child: Text('Restore'),
          onPressed: _isChecking || _isRestoring ? null : _restoreDatabase,
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('Recreate DB'),
          onPressed: _isChecking || _isRestoring ? null : _forceRecreateDatabase,
        ),
        TextButton(
          child: Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

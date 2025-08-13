import 'package:flutter/material.dart';
import '../services/credential_manager.dart';
import '../dialogs/error_history_dialog.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final CredentialManager _credentialManager = CredentialManager();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use Future.delayed to ensure the widget is fully built before loading data
    Future.delayed(Duration.zero, () {
      if (mounted) {
        _loadEntries();
      }
    });
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Map<String, dynamic>> entries = await _credentialManager.getCredentialsWithSettings();
      
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading entries: $e');
      if (mounted) {
        setState(() {
          _entries = [];
          _isLoading = false;
        });
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading settings. Please try again later.'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
            ? const Center(child: Text('No credentials found.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final bool isSelected = entry['is_selected'] == 1;
                  final bool hasError = entry['error'] == 1;
                  
                  return Card(
                    color: hasError ? Colors.red.shade50 : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(entry['name'] ?? 'No Name (ID: ${entry['student_ID']})'),
                            value: isSelected,
                            onChanged: (bool? value) async {
                              if (value != null) {
                                await _credentialManager.updateSettingStatus(
                                  entry['id'], 
                                  value
                                );
                                _loadEntries(); // Reload the list
                              }
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Error: ', style: TextStyle(fontSize: 14)),
                              Switch(
                                value: hasError,
                                activeColor: Colors.red,
                                onChanged: (bool value) async {
                                  await _credentialManager.updateErrorStatus(
                                    entry['id'],
                                    value
                                  );
                                  _loadEntries(); // Reload the list
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.history, color: Colors.blueGrey),
                                tooltip: 'View Error History',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return ErrorHistoryDialog(
                                        profileId: entry['id'],
                                        profileName: entry['name'] ?? 'No Name (ID: ${entry['student_ID']})',
                                      );
                                    }
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                            ],
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
          child: const Text('Refresh'),
          onPressed: _loadEntries,
        ),
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

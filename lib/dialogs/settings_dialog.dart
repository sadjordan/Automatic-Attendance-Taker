import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/credential_manager.dart';
import '../dialogs/error_history_dialog.dart';
import '../dialogs/database_helper_dialog.dart';

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
      // Get entries from database
      List<Map<String, dynamic>> dbEntries = await _credentialManager.getCredentialsWithSettings();
      
      // Convert read-only maps to modifiable maps
      List<Map<String, dynamic>> modifiableEntries = dbEntries.map((entry) {
        // Create a new map with the same data that we can modify
        return Map<String, dynamic>.from(entry);
      }).toList();
      
      if (mounted) {
        setState(() {
          _entries = modifiableEntries;
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
  
  // Update a single entry without reloading the entire list
  Future<void> _updateEntrySelection(int index, int id, bool isSelected) async {
    // Optimistically update UI
    setState(() {
      _entries[index]['is_selected'] = isSelected ? 1 : 0;
    });
    
    // Update in database
    await _credentialManager.updateSettingStatus(id, isSelected);
  }
  
  // Update error status without reloading the entire list
  Future<void> _updateEntryErrorStatus(int index, int id, bool hasError) async {
    // Optimistically update UI
    setState(() {
      _entries[index]['error'] = hasError ? 1 : 0;
    });
    
    // Update in database
    await _credentialManager.updateErrorStatus(id, hasError);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate appropriate dialog dimensions based on screen size
    final Size screenSize = MediaQuery.of(context).size;
    final double dialogWidth = math.min(screenSize.width * 0.85, 600.0);
    final double dialogHeight = math.min(screenSize.height * 0.7, 800.0);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            Divider(),
            
            // Main content area
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                  ? const Center(child: Text('No credentials found.'))
                  : ListView.builder(
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
                                await _updateEntrySelection(index, entry['id'], value);
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
                                  await _updateEntryErrorStatus(index, entry['id'], value);
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
            
            // Action buttons
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Refresh'),
                  onPressed: _loadEntries,
                ),
                TextButton(
                  child: const Text('Database Tools'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return DatabaseHelperDialog();
                      },
                    );
                  },
                ),
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

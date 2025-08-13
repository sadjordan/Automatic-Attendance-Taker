import 'package:flutter/material.dart';
import '../services/credential_manager.dart';

class ErrorHistoryDialog extends StatefulWidget {
  final int profileId;
  final String profileName;

  const ErrorHistoryDialog({
    Key? key,
    required this.profileId,
    required this.profileName,
  }) : super(key: key);

  @override
  State<ErrorHistoryDialog> createState() => _ErrorHistoryDialogState();
}

class _ErrorHistoryDialogState extends State<ErrorHistoryDialog> {
  final CredentialManager _credentialManager = CredentialManager();
  List<Map<String, dynamic>> _errorHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadErrorHistory();
  }

  Future<void> _loadErrorHistory() async {
    try {
      final errorHistory = await _credentialManager.getErrorMessages(widget.profileId);
      setState(() {
        _errorHistory = errorHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load error history: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Error History for ${widget.profileName}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorHistory.isEmpty)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No error history found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _errorHistory.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final error = _errorHistory[index];
                    final timestamp = DateTime.parse(error['timestamp'] as String);
                    final formattedDate = "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
                    
                    return ListTile(
                      title: Text(
                        error['error_message'] as String,
                        style: TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        'Time: $formattedDate',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadErrorHistory();
                  },
                  child: Text('Refresh'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

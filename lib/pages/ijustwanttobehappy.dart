import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/credential_manager.dart';
import '../dialogs/settings_dialog.dart';

final Test = UserScript(
    groupName: "Style Setup",
    source: """
window.addEventListener('load', function(event) {
  // Add minimal styling to make the form easier to see
  document.body.style.padding = '20px';
});
""",
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START);


class Home extends StatefulWidget {
  final Uri? link;
  const Home({super.key, required this.link});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey webViewKey = GlobalKey();
  final CredentialManager _credentialManager = CredentialManager();
  List<Map<String, dynamic>> _selectedCredentials = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  int _currentIndex = -1;
  int _totalProcessed = 0;
  int _successCount = 0;
  String _statusMessage = "Preparing...";
  
  InAppWebViewController? webViewController;
  
  @override
  void initState() {
    super.initState();
    _loadSelectedCredentials();
  }
  
  Future<void> _loadSelectedCredentials() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Loading credentials...";
    });
    
    _selectedCredentials = await _credentialManager.getSelectedCredentials();
    
    setState(() {
      _isLoading = false;
      if (_selectedCredentials.isEmpty) {
        _statusMessage = "No credentials selected. Please go to settings to select credentials.";
      } else {
        _statusMessage = "${_selectedCredentials.length} credentials loaded and ready to process.";
      }
    });
  }
  
  void _processNextCredential() {
    if (_currentIndex >= _selectedCredentials.length - 1 || _selectedCredentials.isEmpty) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "Completed! Processed $_totalProcessed credentials with $_successCount successful.";
      });
      return;
    }
    
    setState(() {
      _currentIndex++;
      _isProcessing = true;
      _statusMessage = "Processing ${_currentIndex + 1} of ${_selectedCredentials.length}: ${_selectedCredentials[_currentIndex]['name']}";
    });
    
    _submitCredential(_selectedCredentials[_currentIndex]);
  }
  
  Future<void> _submitCredential(Map<String, dynamic> credential) async {
    if (webViewController == null) return;
    
    try {
      final studentId = credential['student_ID'];
      final password = credential['password'];
      final name = credential['name'];
      final id = credential['id'];
      
      setState(() {
        _statusMessage = "Processing credential: $name";
      });
      
      String script = """
      (function() {
        const userIdField = document.getElementById('N_QRCODE_DRV_USERID');
        const passwordField = document.getElementById('N_QRCODE_DRV_PASSWORD');
        const loginButton = document.getElementById('N_QRCODE_DRV_BUTTON1');
        
        if (userIdField && passwordField && loginButton) {
          userIdField.value = '$studentId';
          passwordField.value = '$password';
          loginButton.click();
          return true;
        }
        return false;
      })();
      """;
      
      final result = await webViewController!.evaluateJavascript(source: script);
      
      if (result == true) {
        _totalProcessed++;
        _successCount++;
        
        // Check for error messages after submission (could be done by checking page content)
        Future.delayed(Duration(seconds: 2), () async {
          try {
            // This is a basic example - you'll want to customize this to check for actual error messages
            // on your specific form
            String errorCheckScript = """
            (function() {
              // Check for error messages or success indicators on the page
              const errorMessages = document.querySelectorAll('.error-message, .alert-error');
              if (errorMessages.length > 0) {
                return errorMessages[0].innerText;
              }
              return null; // No errors found
            })();
            """;
            
            final errorResult = await webViewController!.evaluateJavascript(source: errorCheckScript);
            
            if (errorResult != null) {
              // Update the database to mark this credential as having an error
              await _credentialManager.updateProfileError(id, 1, "Login error: $errorResult");
              setState(() {
                _statusMessage = "Error with $name: $errorResult";
              });
            }
          } catch (e) {
            print('Error checking for form submission results: $e');
          }
          
          _processNextCredential();
        });
      } else {
        // Form elements not found
        _totalProcessed++;
        final errorMsg = "Form elements not found";
        await _credentialManager.updateProfileError(id, 1, errorMsg);
        
        setState(() {
          _statusMessage = "Error: $errorMsg for $name";
        });
        
        // Try next credential anyway after a delay
        Future.delayed(Duration(seconds: 1), () {
          _processNextCredential();
        });
      }
    } catch (e) {
      print('Error submitting credential: $e');
      _totalProcessed++;
      
      try {
        // Try to update the database with the error
        await _credentialManager.updateProfileError(credential['id'], 1, e.toString());
      } catch (_) {
        // If this fails, just continue
      }
      
      setState(() {
        _statusMessage = "Error processing ${credential['name']}: $e";
      });
      
      Future.delayed(Duration(seconds: 1), () {
        _processNextCredential();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Home page received link: ${widget.link}");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance System"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSelectedCredentials,
            tooltip: 'Refresh Credentials',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Show settings dialog
              showDialog(
                context: context,
                builder: (context) => const SettingsDialog()
              ).then((_) => _loadSelectedCredentials());
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(children: <Widget>[
          // Status Panel
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                if (_isLoading)
                  LinearProgressIndicator(),
                if (_isProcessing)
                  Row(
                    children: [
                      Expanded(child: LinearProgressIndicator(
                        value: _selectedCredentials.isEmpty ? 0 : 
                               (_currentIndex + 1) / _selectedCredentials.length,
                      )),
                      SizedBox(width: 8),
                      Text("${_currentIndex + 1}/${_selectedCredentials.length}")
                    ],
                  ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading || _isProcessing ? null : () {
                        if (_selectedCredentials.isNotEmpty) {
                          _currentIndex = -1;
                          _totalProcessed = 0;
                          _successCount = 0;
                          _processNextCredential();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No credentials selected'))
                          );
                        }
                      },
                      child: Text('Start Processing'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _loadSelectedCredentials,
                      child: Text('Refresh Credentials'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // WebView
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest:
                      URLRequest(url: widget.link != null ? WebUri.uri(widget.link!) : null),
                  initialUserScripts: UnmodifiableListView<UserScript>([Test]),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  onLoadStop: (controller, url) {
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                    });
                  },
                  onLoadError: (controller, url, code, message) {
                    setState(() {
                      _isLoading = false;
                      _statusMessage = "Error loading page: $message";
                    });
                  },
                ),
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ]));
  }
}

// import 'package:flutter/material.dart';

// class Home extends StatelessWidget {
//   const Home({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

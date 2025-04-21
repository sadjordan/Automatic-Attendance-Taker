import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

final Test = UserScript(
    groupName: "A test",
    source: """
window.addEventListener('load', function(event) {
  document.body.style.backgroundColor = 'blue';
  document.body.style.padding = '20px';
});
""",
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START);

final attendance = UserScript(
  source: """ window.addEventListener('load', function () {
  const studentID = '241UC24151';
  const password = 'Not today';

  // Find the input fields and login button by their IDs
  const userIdField = document.getElementById('N_QRCODE_DRV_USERID');
  const passwordField = document.getElementById('N_QRCODE_DRV_PASSWORD');
  const loginButton = document.getElementById('N_QRCODE_DRV_BUTTON1');

  // Check if the elements exist on the page
  if (userIdField && passwordField && loginButton) {
    // Enter the credentials
    userIdField.value = studentID;
    passwordField.value = password;

    // Click the login button
    loginButton.click();
  } else {
    console.error('One or more elements were not found on the page.');
  }
  }); """,
  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START);


class Home extends StatefulWidget {
  final Uri? link;
  const Home({super.key, required this.link});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    print("Home page received link: ${widget.link}");
    return Scaffold(
      appBar: AppBar(
        title: const Text("trash"),
      ),
      body: Column(children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest:
                      URLRequest(url: widget.link != null ? WebUri.uri(widget.link!) : null),
                  initialUserScripts: UnmodifiableListView<UserScript>(
                      [Test, attendance]),
                  onWebViewCreated: (controller) {
                    print("here");
                    webViewController = controller;
                    controller.addJavaScriptHandler(
                        handlerName: 'Does stuff',
                        callback: (arguments) {
                          final String h1InnerText = arguments[0];
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('h1 clicked'),
                                content: Text(h1InnerText),
                              );
                            },
                          );
                        });
                  },
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

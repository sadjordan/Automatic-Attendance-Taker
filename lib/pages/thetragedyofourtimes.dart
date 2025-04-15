import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: const Center(
        child: Text('Profile')
      )
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// class Profile extends StatefulWidget {
//   const Profile({super.key});

//   @override
//   State<Profile> createState() => _ProfileState();
// }

// class _ProfileState extends State<Profile> {
//   final GlobalKey webViewKey = GlobalKey();

//   InAppWebViewController? webViewController;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Something"),
//       ),
//       body: Column(children: <Widget>[
//           Expanded(
//             child: Stack(
//               children: [
//                 InAppWebView(
//                   key: webViewKey,
//                   initialUrlRequest:
//                       URLRequest(url: WebUri('https://google.com')),
//                   // initialUserScripts: UnmodifiableListView<UserScript>(
//                   //     [userScript1, userScript2, userScript3]),
//                   onWebViewCreated: (controller) {
//                     webViewController = controller;
//                     controller.addJavaScriptHandler(
//                         handlerName: 'h1Click',
//                         callback: (arguments) {
//                           final String h1InnerText = arguments[0];
//                           showDialog(
//                             context: context,
//                             builder: (context) {
//                               return AlertDialog(
//                                 title: const Text('h1 clicked'),
//                                 content: Text(h1InnerText),
//                               );
//                             },
//                           );
//                         });
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ]));
//   }
// }